/**
 * MIT License
 *
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import { RNComponentContext } from '@rnoh/react-native-openharmony';
import webview from '@ohos.web.webview';
import { url as OSUrl } from '@kit.ArkTS';
import { RNC } from '@rnoh/react-native-openharmony/generated';
import Logger from './Logger';
import { BaseOperate } from './WebViewBaseOperate';
import {
  AlertEvent,
  CACHE_MODE,
  JAVASCRIPT_INTERFACE,
  ONE_HUNDRED,
  EIGHT,
  ResultType,
  RNCWebViewBridge,
  WebViewEventParams,
  WebViewNewSource,
  WebViewOverScrollMode,
  ZERO,
  COMMAND_NAME,
  WebViewDescriptor,
  REFRESH_OFFSET,
  MINHEIGHT,
} from './Magic';
import { bundleManager } from '@kit.AbilityKit';

export const TAG = "WebView"

export const WEB_VIEW = "RNCWebView"

@Component
export struct RNCWebView {
  public static readonly NAME = RNC.RNCWebView.NAME
  ctx!: RNComponentContext
  tag: number = ZERO
  source: WebViewNewSource = {
    uri: "",
    method: "",
    body: "",
    html: "",
    baseUrl: ""
  }
  html: string | undefined = "";
  url: string | Resource = "";
  controller: webview.WebviewController = new webview.WebviewController();
  javaScriptEnable: boolean = true;
  allowFileAccess: boolean = true;
  forceDark: boolean = true;
  minFontSize: number = EIGHT;
  overScrollMode: OverScrollMode = OverScrollMode.NEVER;
  progress: number = ZERO;
  cacheMode: number = CacheMode.Default;
  lockIdentifier: string = "";
  requestUrl: string = "";
  bundleName: string = "";
  messagingEnabled: boolean = false;
  hasRegisterJavaScriptProxy: boolean = false;
  controllerAttached: boolean = false;
  renderMode: RenderMode = RenderMode.SYNC_RENDER;
  scrollEnabled = true;
  nestedScroll = NestedScrollMode.SELF_FIRST;
  headers: Array<webview.WebHeader> = []
  injectedJavaScriptBeforeContentLoaded: Array<ScriptItem> = [
    { script: '', scriptRules: ["*"] }
  ];
  allowPageStartInProgress = true;
  @State webviewWidth: number = ZERO
  @State webviewHeight: number = ZERO
  @State isRefreshing: boolean = false
  @State mode: MixedMode = MixedMode.All;
  private unregisterDescriptorChangesListener?: () => void = undefined
  private cleanupCommandCallback?: () => void = undefined
  private eventEmitter: RNC.RNCWebView.EventEmitter | undefined = undefined
  private cleanUpCallbacks: (() => void)[] = []
  private descriptorWrapper: WebViewDescriptor = Object() as WebViewDescriptor
  private webViewBaseOperate: BaseOperate | null = null

  aboutToAppear() {
    try {
      this.initVariable()
      this.getBundleName()
      this.url = this.source.uri as string;
      this.onDescriptorWrapperChange(this.descriptorWrapper)
      this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
        (newDescriptor) => {
          this.onDescriptorWrapperChange(newDescriptor as WebViewDescriptor)
        }
      )
      BaseOperate.setThirdPartyCookiesEnabled(this.descriptorWrapper.rawProps.thirdPartyCookiesEnabled)
      webview.WebviewController.setWebDebuggingAccess(this.descriptorWrapper.rawProps.webviewDebuggingEnabled)
      this.registerCommandCallback()
      if (this.hasIncognito()) {
        this.cacheMode = CacheMode.Online;
      }
      if (this.source.headers) {
        this.source.headers.forEach(item => {
          if (item.name && item.value) {
            this.headers.push({ headerKey: item.name, headerValue: item.value })
          }
        })
      }
    } catch (error) {
      Logger.error(TAG, `[RNOH]Errorcode: ${error.code}, Message: ${error.message}`);
    }

  }

  hasIncognito(): boolean {
    return this.descriptorWrapper.rawProps.incognito && this.descriptorWrapper.rawProps.incognito === true
  }

  createWebViewEvent(type: string): WebViewEventParams {
    return this.webViewBaseOperate?.createWebViewEvent({ type, progress: this.progress }) as WebViewEventParams;
  }

  aboutToDisappear() {
    this.cleanupCommandCallback?.()
    this.unregisterDescriptorChangesListener?.()
    this.cleanUpCallbacks.forEach(cb => cb())
    try {
      if (this.hasIncognito()) {
        this.webViewBaseOperate?.setIncognito()
      }
      this.controller.deleteJavaScriptRegister(JAVASCRIPT_INTERFACE)
      this.controller.refresh()
      this.hasRegisterJavaScriptProxy = false
      this.webViewBaseOperate = null
    } catch (error) {
      Logger.error(TAG, `[RNOH]Errorcode: ${error.code}, Message: ${error.message}`);
    }
  }

  registerCommandCallback() {
    this.cleanupCommandCallback = this.ctx.componentCommandReceiver.registerCommandCallback(
      this.tag,
      (command: COMMAND_NAME, args: string[]) => this.webViewBaseOperate?.registerCommandCallback(command, args));
  }

  onLoadingStart() {
    this.webViewBaseOperate?.emitLoadingStart({ progress: this.progress })
  }

  onProgressChange(event: OnProgressChangeEvent) {
    this.progress = event.newProgress
    // 修复单页面应用切换路由时 onPageBegin 未触发的问题
    if (this.controller.getUrl() !== this.url && this.progress < ONE_HUNDRED && this.allowPageStartInProgress) {
      this.allowPageStartInProgress = false;
      this.onLoadingStart();
    }
    this.webViewBaseOperate?.emitProgressChange({ progress: this.progress })
    if (this.progress === ONE_HUNDRED) {
      this.allowPageStartInProgress = true;
    }
  }

  onLoadingFinish() {
    this.webViewBaseOperate?.emitLoadingFinish({ progress: this.progress })
    this.isRefreshing = false
  }

  runInjectedJavaScript() {
    let injectedJS = this.descriptorWrapper.rawProps.injectedJavaScript
    if (this.javaScriptEnable && injectedJS != "" && this.controllerAttached) {
      try {
        this.controller.runJavaScript("(function() {\n" + injectedJS + ";\n})();")
          .then((result) => {
            Logger.debug(TAG, '[RNOH] result: ' + result);
          })
          .catch((error: string | Error) => {
            Logger.error(TAG, "[RNOH] error: " + error);
          })
      } catch (error) {
        Logger.error(TAG, `[RNOH]Errorcode: ${error.code}, Message: ${error.message}`);
      }
    }
  }

  getJsDialogTitle() {
    const url = this.controller.getUrl()
    // 对于 data: URL，只显示 'JavaScript'，类似于 Chrome
    let title = 'JavaScript';
    const isDataUrl = (url !== null) && url.startsWith("data:");


    if (!isDataUrl) {
      try {
        const dialogUrl = OSUrl.URL.parseURL(url);
        title = `网址为”${dialogUrl.protocol}//${dialogUrl.host}“的网页显示：`;
      } catch (ex) {
        title = url;
      }
    }

    return title;
  }

  onJavascriptAlert(event?: AlertEvent) {
    if (event) {
      AlertDialog.show({
        title: this.getJsDialogTitle(),
        message: event.message,
        alignment: DialogAlignment.Center,
        secondaryButton: {
          value: this.resourceToString($r('app.string.determined')),
          action: () => event.result.handleConfirm()
        },
        cancel: () => event.result.handleCancel(),
      })
    }
    return true
  }

  onJavascriptConfirm(event?: AlertEvent) {
    if (event) {
      AlertDialog.show({
        title: this.getJsDialogTitle(),
        message: event.message,
        alignment: DialogAlignment.Center,
        secondaryButton: {
          value: this.resourceToString($r('app.string.determined')),
          action: () => event.result.handleConfirm()
        },
        cancel: () => event.result.handleCancel(),
        primaryButton: {
          value: this.resourceToString($r('app.string.cancel')),
          action: () => event.result.handleCancel()
        },
      })
    }
    return true
  }

  ignoreSilentHardwareSwitchMethods(ignoreSilentHardwareSwitch: boolean) {
    this.webViewBaseOperate?.ignoreSilentHardwareSwitchMethods(ignoreSilentHardwareSwitch)
  }

  controllerAttachedInit(): void {
    this.controllerAttached = true;
    this.eventEmitter = new RNC.RNCWebView.EventEmitter(this.ctx.rnInstance, this.tag)
    this.webViewBaseOperate = new BaseOperate(this.eventEmitter, this.controller)
    this.webViewBaseOperate.setCustomUserAgent(this.descriptorWrapper.rawProps.userAgent,
      this.descriptorWrapper.rawProps.applicationNameForUserAgent)
    this.webViewBaseOperate.setFraudulentWebsiteWarningEnabled(this.descriptorWrapper.rawProps.fraudulentWebsiteWarningEnabled)
    let baseUrl = this.source.baseUrl
    let uri = this.source.uri
    if (this.source.html != undefined && this.source.html != "") {
      try {
        this.controller.loadData(
          this.source.html,
          "text/html",
          "UTF-8",
          baseUrl,
          " "
        );
      } catch (error) {
        Logger.error(TAG, "error:" + error)
      }
    } else if (uri != undefined && uri != "") {
      this.controller.loadUrl(uri, this.headers);
    } else {
      this.controller.loadUrl(uri, this.headers);
    }
    if (!this.hasRegisterJavaScriptProxy) {
      this.registerPostMessage()
    }
  }

  onPageBegin() {
    try {
      if (this.controller.getUrl() === this.url) {
        this.onLoadingStart();
      }
      this.controller.setScrollable(this.scrollEnabled)
      this.ignoreSilentHardwareSwitchMethods(this.descriptorWrapper.rawProps.ignoreSilentHardwareSwitch)
    } catch (error) {
      Logger.debug(TAG,
        `[RNOH] setignoreSilentHardwareSwitch and setScrollable ErrorCode: ${error.code},  Message: ${error.message}, userAgent: ${this.descriptorWrapper.rawProps.userAgent}`);
    }
  }

  getBundleName() {
    let bundleFlags =
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_HAP_MODULE | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_ABILITY |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;

    try {
      bundleManager.getBundleInfoForSelf(bundleFlags, (error, data) => {
        if (error) {
          Logger.error(TAG,
            `[RNOH] getBundleInfoForSelf failed ErrorCode: ${error.code},  Message: ${error.message}`);
        } else {
          this.bundleName = JSON.stringify(data.name)
        }
      });
    } catch (error) {
      Logger.error(TAG,
        `[RNOH] getBundleInfoForSelf failed ErrorCode: ${error.code},  Message: ${error.message}`);
    }
  }

  resourceToString(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource)
  }

  onPageEnd() {
    this.runInjectedJavaScript()
    this.onLoadingFinish()
  }

  getPermissionDialogMessage(event: OnPermissionRequestEvent) {
    let permissionDialogMessage = ''
    permissionDialogMessage = event.request.getAccessibleResource().toString()
    switch (permissionDialogMessage) {
      case ProtectedResourceType.VIDEO_CAPTURE:
        permissionDialogMessage = this.resourceToString($r('app.string.use_your_camera'))
        break;
      case ProtectedResourceType.AUDIO_CAPTURE:
        permissionDialogMessage = this.resourceToString($r('app.string.use_your_microphone'))
        break;
      case ProtectedResourceType.MidiSysex:
        permissionDialogMessage = this.resourceToString($r('app.string.midi_sysex_resources'))
        break;
      case ProtectedResourceType.VIDEO_CAPTURE + "," + ProtectedResourceType.AUDIO_CAPTURE:
        permissionDialogMessage = this.resourceToString($r('app.string.use_your_camera_and_microphone'))
        break;
    }
    return permissionDialogMessage;
  }

  onLoadIntercept(event: OnLoadInterceptEvent): boolean {
    this.webViewBaseOperate?.emitShouldStartLoadWithRequest(event)
    return false
  }

  onOverrideUrlLoading(event: WebResourceRequest) {
    this.webViewBaseOperate?.emitShouldStartLoadWithRequestOverrideUrlLoading(event)
    return false
  }

  build() {
    Stack() {
      Web({ src: "", controller: this.controller, renderMode: this.renderMode })
        .mixedMode(this.mode)
        .onPermissionRequest((event: OnPermissionRequestEvent) => {
          if (event) {
            AlertDialog.show({
              title: this.resourceToString($r('app.string.on_confirm')) + event.request.getOrigin(),
              message: this.getPermissionDialogMessage(event),
              alignment: DialogAlignment.Center,
              primaryButton: {
                value: $r('app.string.deny'),
                action: () => {
                  event.request.deny();
                }
              },
              secondaryButton: {
                value: $r('app.string.on_confirm'),
                action: () => {
                  event.request.grant(event.request.getAccessibleResource());
                }
              },
              cancel: () => {
                event.request.deny();
              }
            })
          }
        })

        .width(this.webviewWidth)
        .height(this.webviewHeight)
        .fileAccess(this.allowFileAccess)
        .constraintSize({ minHeight: MINHEIGHT })
        .overScrollMode(this.overScrollMode)
        .javaScriptAccess(this.javaScriptEnable)
        .javaScriptOnDocumentStart(this.injectedJavaScriptBeforeContentLoaded)
        .horizontalScrollBarAccess(this.descriptorWrapper.rawProps.showsHorizontalScrollIndicator)
        .verticalScrollBarAccess(this.descriptorWrapper.rawProps.showsVerticalScrollIndicator)
        .overviewModeAccess(this.descriptorWrapper.rawProps.scalesPageToFit)
        .textZoomRatio(this.descriptorWrapper.rawProps.textZoom)
        .darkMode(BaseOperate.getColorMode(this.ctx.uiAbilityContext, this.descriptorWrapper.rawProps.forceDarkOn))
        .forceDarkAccess(this.forceDark)
        .cacheMode(this.cacheMode)
        .minFontSize(this.minFontSize)
        .domStorageAccess(this.descriptorWrapper.rawProps.domStorageEnabled)
        .zoomAccess(this.descriptorWrapper.rawProps.scalesPageToFit)
        .overScrollMode(this.overScrollMode)
        .onProgressChange((event: OnProgressChangeEvent) => this.onProgressChange(event))
        .onScroll((event: OnScrollEvent) => this.webViewBaseOperate?.emitScroll(event))
        .nestedScroll({
          scrollForward: this.nestedScroll,
          scrollBackward: this.nestedScroll,
        })
        .onPageBegin(() => this.onPageBegin())
        .onPageEnd(() => this.onPageEnd())
        .onErrorReceive((event: OnErrorReceiveEvent) => this.webViewBaseOperate?.emitLoadingError(event))
        .onHttpErrorReceive((event: OnHttpErrorReceiveEvent) => this.webViewBaseOperate?.emitHttpError(event))
        .onControllerAttached(() => this.controllerAttachedInit())
        .onAlert((event: AlertEvent) => this.onJavascriptAlert(event))
        .onConfirm((event: AlertEvent) => this.onJavascriptConfirm(event))
        .onDownloadStart((event: OnDownloadStartEvent) => this.webViewBaseOperate?.onDownloadStart(event))
        .geolocationAccess(this.descriptorWrapper.rawProps.geolocationEnabled)
        .mediaPlayGestureAccess(this.descriptorWrapper.rawProps.mediaPlaybackRequiresUserAction)
        .onRenderExited((event: OnRenderExitedEvent) => this.webViewBaseOperate?.onRenderExited(event))
        .onLoadIntercept((event: OnLoadInterceptEvent) => this.onLoadIntercept(event))
        .onTitleReceive((event: OnTitleReceiveEvent) => this.webViewBaseOperate?.onTitleReceive(event))
    }
    .width(this.webviewWidth)
    .height(this.webviewHeight)
    .position({
      x: this.descriptorWrapper.layoutMetrics.frame.origin.x,
      y: this.descriptorWrapper.layoutMetrics.frame.origin.y
    })
  }

  private onDescriptorWrapperChange(descriptorWrapper: WebViewDescriptor) {
    this.initVariable()
    this.descriptorWrapper = descriptorWrapper
    if (this.html != "" && this.html != this.source.html) {
      Logger.debug(TAG, "[RNOH] html is update")
      this.html = this.source.html
      if (this.controllerAttached) {
        try {
          this.controller.loadData(
            this.source.html,
            "text/html",
            "UTF-8",
            this.source.baseUrl,
            " "
          );
        } catch (error) {
          Logger.error(TAG, "error: " + error)
        }
      }
    } else if (this.source.uri != "" && this.url != this.source.uri) {
      Logger.debug(TAG, `[RNOH] newDescriptor props update uri: ` + this.source.uri);
      this.url = this.source.uri as string;
      if (this.controllerAttached) {
        this.controller.loadUrl(this.descriptorWrapper.rawProps.newSource.uri, this.headers)
      }
    }
    if (this.controllerAttached) {
      this.controller?.setScrollable(this.descriptorWrapper.rawProps.scrollEnabled)
    }
  }

  private initVariable() {
    this.descriptorWrapper = this.ctx.descriptorRegistry.getDescriptor<WebViewDescriptor>(this.tag)
    this.javaScriptEnable = this.descriptorWrapper.rawProps.javaScriptEnabled;
    this.minFontSize =
      this.descriptorWrapper.rawProps.minimumFontSize ? this.descriptorWrapper.rawProps.minimumFontSize : EIGHT;
    this.cacheMode =
      this.descriptorWrapper.rawProps.cacheEnabled ?
        this.webViewBaseOperate?.transCacheMode(this.descriptorWrapper.rawProps.cacheMode as CACHE_MODE) as number :
      CacheMode.Online;
    this.source = {
      uri: this.descriptorWrapper.rawProps.newSource.uri ?? "",
      method: this.descriptorWrapper.rawProps.newSource.method ?? "",
      body: this.descriptorWrapper.rawProps.newSource.body ?? "",
      html: this.descriptorWrapper.rawProps.newSource.html ?? "",
      baseUrl: this.descriptorWrapper.rawProps.newSource.baseUrl ?? "",
      headers: this.descriptorWrapper.rawProps.newSource.headers ?? []
    }
    if (this.source.headers) {
      this.source.headers.forEach(item => {
        if (item.name && item.value) {
          this.headers.push({ headerKey: item.name, headerValue: item.value })
        }
      })
    }
    this.html = this.source.html
    this.webviewWidth = this.descriptorWrapper.rawProps.width
    this.webviewHeight = this.descriptorWrapper.rawProps.height
    this.scrollEnabled = this.descriptorWrapper.rawProps.scrollEnabled;
    // 当禁止滚动时，使用父组件滚动
    this.nestedScroll = this.scrollEnabled ? NestedScrollMode.SELF_FIRST : NestedScrollMode.PARENT_FIRST;
    if (this.source.uri && this.source.uri.toString().startsWith("asset://")) {
      this.source.uri = $rawfile(this.source.uri.toString().replace("asset://", this.ctx.rnInstance.getAssetsDest()));
    }

    if (this.descriptorWrapper.rawProps.overScrollMode === WebViewOverScrollMode.ALWAYS) {
      this.overScrollMode = OverScrollMode.ALWAYS
    } else if (this.descriptorWrapper.rawProps.overScrollMode === WebViewOverScrollMode.NEVER) {
      this.overScrollMode = OverScrollMode.NEVER
    }

    this.overScrollMode = this.descriptorWrapper.rawProps.bounces ? OverScrollMode.ALWAYS : OverScrollMode.NEVER;

    if (this.descriptorWrapper.rawProps.injectedJavaScriptBeforeContentLoaded) {
      this.injectedJavaScriptBeforeContentLoaded = [
        { script: this.descriptorWrapper.rawProps.injectedJavaScriptBeforeContentLoaded, scriptRules: ["*"] }
      ];
    }
  }

  private registerPostMessage() {
    if (this.messagingEnabled == this.descriptorWrapper.rawProps.messagingEnabled) {
      return;
    }
    this.messagingEnabled = this.descriptorWrapper.rawProps.messagingEnabled;
    if (this.messagingEnabled) {
      let bridge: RNCWebViewBridge = {
        postMessage: (data: string) => {
          Logger.debug(TAG, `[RNOH] bridge postMessage,  ${JSON.stringify(data)}`);
          if (this.controller != null) {
            let result: WebViewEventParams = this.createWebViewEvent("onMessage")
            if (result) {
              result.data = data.toString()
              result.lockIdentifier = ZERO
              this.eventEmitter!.emit("message", result as ResultType);
            }
          }
        }
      };
      this.controller.registerJavaScriptProxy(bridge, JAVASCRIPT_INTERFACE, ["postMessage"])
      this.source.uri ?
      this.controller.loadUrl(this.source.uri, this.headers) : this.controller.refresh()
      this.hasRegisterJavaScriptProxy = true
    }
  }
}