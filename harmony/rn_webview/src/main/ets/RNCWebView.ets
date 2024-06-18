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

import { Descriptor, RNOHContext, ViewBaseProps } from '@rnoh/react-native-openharmony';
import webview from '@ohos.web.webview';
import { url as OSUrl } from '@kit.ArkTS';
import { CallbackState, ShouldRequestUrl } from './ShouldRequestUrl';
import { RNC } from './namespace';
import Logger from './Logger';

export class WebViewNewSourceHeader {
  name?: string
  value?: string
}

export class WebViewNewSource {
  uri?: string | Resource
  method?: string
  body?: string
  headers?: WebViewNewSourceHeader[]
  html?: string
  baseUrl?: string
}

interface AlertEvent {
  url: string;
  message: string;
  result: JsResult;
}

const TAG = "WebView"

export const WEB_VIEW = "RNCWebView"

const JAVASCRIPT_INTERFACE = "ReactNativeWebView";

export interface WebViewProps extends ViewBaseProps {
  newSource: WebViewNewSource
  javaScriptEnabled: boolean
  injectedJavaScript: string
  messagingEnabled: boolean
  showsHorizontalScrollIndicator: boolean
  showsVerticalScrollIndicator: boolean
  textZoom: number
  cacheEnabled: boolean
  cacheMode: number
  domStorageEnabled: boolean
  scalesPageToFit: boolean
  messagingModuleName: string
  shouldStartLoadWithRequestEnabled: boolean
  webviewDebuggingEnabled: boolean
  scrollEnabled: boolean
  incognito: boolean
}

export class RNCWebViewBridge {
  postMessage!: (data: string) => void;
}
export class WebViewEventParams {
  type: string
  url?: string
  loading?: boolean
  title?: string
  canGoBack?: boolean
  canGoForward?: boolean
  lockIdentifier?: number
  data?: string

  constructor(type: string) {
    this.type = type
  }
}

export enum  CACHE_MODE {
  'LOAD_DEFAULT' = 'LOAD_DEFAULT',
  'LOAD_CACHE_ELSE_NETWORK' = 'LOAD_CACHE_ELSE_NETWORK' ,
  'LOAD_NO_CACHE' = 'LOAD_NO_CACHE' ,
  'LOAD_CACHE_ONLY' = 'LOAD_CACHE_ONLY',
}

export class ResultType {
  url: string
  loading: boolean
  title: string
  canGoBack: boolean
  canGoForward: boolean
  lockIdentifier: number
  data: string

  constructor(url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number, data: string) {
    this.url = url
    this.loading = loading
    this.title = title
    this.canGoBack = canGoBack
    this.canGoForward = canGoForward
    this.lockIdentifier = lockIdentifier
    this.data = data
  }
}

export type WebViewViewDescriptor = Descriptor<"RNCWebView", WebViewProps>

@Component
export struct RNCWebView {
  public static readonly NAME = RNC.RNCWebView.NAME
  ctx!: RNOHContext
  tag: number = 0
  source: WebViewNewSource = {
    uri: "",
    method: "",
    body: "",
    html: "",
    baseUrl: ""
  }
  html: string | undefined = ""
  url: string | Resource = ""
  private unregisterDescriptorChangesListener?: () => void = undefined
  private cleanupCommandCallback?: () => void = undefined
  controller: webview.WebviewController = new webview.WebviewController();
  javaScriptEnable: boolean = true
  overScrollMode: OverScrollMode = OverScrollMode.NEVER
  progress: number = 0
  cacheMode: number = CacheMode.Default
  lockIdentifier: string = "";
  requestUrl: string = "";
  messagingEnabled: boolean = false;
  hasRegisterJavaScriptProxy: boolean = false;
  controllerAttached: boolean = false;
  renderMode: RenderMode = RenderMode.SYNC_RENDER;
  scrollEnabled = true;
  nestedScroll = NestedScrollMode.SELF_FIRST;
  injectedJavaScriptBeforeContentLoaded: Array<ScriptItem> = [
    { script: '', scriptRules: ["*"] }
  ];
  allowPageStartInProgress = true;
  @State webviewWidth: number = 0
  @State webviewHeight: number = 0
  private eventEmitter: RNC.RNCWebView.EventEmitter | undefined = undefined
  private cleanUpCallbacks: (() => void)[] = []
  private descriptorWrapper: RNC.RNCWebView.DescriptorWrapper = {} as RNC.RNCWebView.DescriptorWrapper

  private onDescriptorWrapperChange(descriptorWrapper: RNC.RNCWebView.DescriptorWrapper) {
    this.descriptorWrapper = descriptorWrapper
    this.initVariable()
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
        this.controller.loadUrl(this.descriptorWrapper.props.newSource.uri)
      }
    }
    if (this.controllerAttached) {
      this.controller?.setScrollable(this.descriptorWrapper.props.scrollEnabled)
    }
  }

  aboutToAppear() {
    this.eventEmitter = new RNC.RNCWebView.EventEmitter(this.ctx.rnInstance, this.tag)
    this.descriptorWrapper = this.ctx.descriptorRegistry.findDescriptorWrapperByTag<RNC.RNCWebView.DescriptorWrapper>(this.tag)!

    this.initVariable()
    this.cleanUpCallbacks.push(this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (_descriptor, newDescriptorWrapper) => {
        this.onDescriptorWrapperChange(newDescriptorWrapper! as RNC.RNCWebView.DescriptorWrapper)
      }
    ))

    this.registerCommandCallback()

    if (this.hasIncognito()) {
      this.cacheMode = CacheMode.Online;
    }
  }

  hasIncognito(): boolean {
    return this.descriptorWrapper.props.incognito === true
  }

  private initVariable() {
    this.javaScriptEnable = this.descriptorWrapper.props.javaScriptEnabled;
    this.cacheMode =
      this.descriptorWrapper.props.cacheEnabled ? this.transCacheMode(this.descriptorWrapper.props.cacheMode as CACHE_MODE) : CacheMode.Online;
    this.source = {
      uri: this.descriptorWrapper.props.newSource.uri ?? "",
      method: this.descriptorWrapper.props.newSource.method ?? "",
      body: this.descriptorWrapper.props.newSource.body ?? "",
      html: this.descriptorWrapper.props.newSource.html ?? "",
      baseUrl: this.descriptorWrapper.props.newSource.baseUrl ?? ""
    }
    this.html = this.source.html
    this.webviewWidth = this.descriptorWrapper.width
    this.webviewHeight = this.descriptorWrapper.height
    this.scrollEnabled = this.descriptorWrapper.props.scrollEnabled;
    // 当禁止滚动时，使用父组件滚动
    this.nestedScroll = this.scrollEnabled ? NestedScrollMode.SELF_FIRST : NestedScrollMode.PARENT_FIRST;
    if (this.source.uri && this.source.uri.toString().startsWith("asset://")) {
      this.source.uri = $rawfile(this.source.uri.toString().replace("asset://", this.ctx.rnInstance.getAssetsDest()));
    }
    this.url = this.source.uri as string;

    if(this.descriptorWrapper.props.overScrollMode === 'always') {
      this.overScrollMode = OverScrollMode.ALWAYS
    } else if(this.descriptorWrapper.props.overScrollMode === 'never') {
      this.overScrollMode = OverScrollMode.NEVER
    }

    this.overScrollMode = this.descriptorWrapper.props.bounces ? OverScrollMode.ALWAYS : OverScrollMode.NEVER;

    if (this.descriptorWrapper.props.injectedJavaScriptBeforeContentLoaded) {
      this.injectedJavaScriptBeforeContentLoaded = [
        { script: this.descriptorWrapper.props.injectedJavaScriptBeforeContentLoaded, scriptRules: ["*"] }
      ];
    }
  }

  private registerPostMessage() {
    if (this.messagingEnabled == this.descriptorWrapper.props.messagingEnabled) {
      return;
    }
    this.messagingEnabled = this.descriptorWrapper.props.messagingEnabled;
    if (this.messagingEnabled) {
      let bridge: RNCWebViewBridge = {
        postMessage: (data: string) => {
          Logger.debug(TAG, `[RNOH] bridge postMessage,  ${JSON.stringify(data)}`);
          if (this.controller != null) {
            let result: WebViewEventParams = this.createWebViewEvent("onMessage")
            result.data = data.toString()
            result.lockIdentifier = 0
            this.eventEmitter!.emit("message", result as ResultType);
          }
        }
      };
      this.controller.registerJavaScriptProxy(bridge, JAVASCRIPT_INTERFACE, ["postMessage"])
      this.controller.refresh()
      this.hasRegisterJavaScriptProxy = true
    }
  }

  createWebViewEvent(param: string): WebViewEventParams {
    let result: WebViewEventParams = new WebViewEventParams(param);
    result.loading = this.progress != 100
    try {
      result.url = this.controller.getUrl();
      result.title = this.controller.getTitle();
      result.canGoBack = this.controller.accessBackward();
      result.canGoForward = this.controller.accessForward();
    } catch (error) {
      Logger.error(TAG, `[RNOH]Errorcode: ${error.code}, Message: ${error.message}`);
      result.url = "";
      result.title = "";
      result.canGoBack = false;
      result.canGoForward = false;
    }
    return result;
  }

  aboutToDisappear() {
    this.cleanupCommandCallback?.()
    this.unregisterDescriptorChangesListener?.()
    Logger.debug(TAG, `[RNOH] aboutToDisappear`)
    this.cleanUpCallbacks.forEach(cb => cb())
    try {
      if (this.hasIncognito()) {
        this.controller.clearHistory()
        webview.WebCookieManager.clearAllCookiesSync(true);
        webview.WebCookieManager.clearSessionCookieSync()
        webview.WebStorage.deleteAllData();
      }
    } catch (e) {
      Logger.error(TAG, `[RNOH]Errorcode: ${e.code}, Message: ${e.message}`);
    }

    try {
      this.controller.deleteJavaScriptRegister(JAVASCRIPT_INTERFACE)
      this.controller.refresh()
      this.hasRegisterJavaScriptProxy = false

    } catch (error) {
      Logger.error(TAG, `[RNOH]Errorcode: ${error.code}, Message: ${error.message}`);
    }
  }

  transCacheMode(cacheMode: CACHE_MODE): CacheMode {
    let mode = CacheMode.Default
    switch (cacheMode) {
      case CACHE_MODE.LOAD_DEFAULT:
        mode = CacheMode.Default
        break;
      case CACHE_MODE.LOAD_CACHE_ELSE_NETWORK:
        mode = CacheMode.None
        break;
      case CACHE_MODE.LOAD_NO_CACHE:
        mode = CacheMode.Online
        break;
      case CACHE_MODE.LOAD_CACHE_ONLY:
        mode = CacheMode.Only
        break;
      default:
        break;
    }
    return mode
  }

  registerCommandCallback() {
    this.cleanupCommandCallback = this.ctx.componentCommandReceiver.registerCommandCallback(
      this.tag,
      (command, args: string[]) => {
        switch (command) {
          case "injectJavaScript":
            Logger.debug(TAG, `[RNOH] injectJavaScript,${JSON.stringify(args)}`)
            if (this.controllerAttached) {
              try {
                this.controller.runJavaScript("(function() {\n" + args[0] + ";\n})();")
              } catch (error) {
                Logger.error(TAG, "error: " + error)
              }
            }
            break
          case "postMessage":
            Logger.debug(TAG, `[RNOH] postMessage,${JSON.stringify(args)}`)
            let data = JSON.stringify({ data: args[0] })
            let result: string = "(function () {" +
              "var event;" +
              "var data = " + data.toString() + ";" +
              "try {" +
              "event = new MessageEvent('message', data);" +
              "} catch (e) {" +
              "event = document.createEvent('MessageEvent');" +
              "event.initMessageEvent('message', true, true, data.data, data.origin, data.lastEventId, data.source);" +
              "}" +
              "document.dispatchEvent(event);" +
              "})();"
            if (this.controllerAttached) {
              try {
                this.controller.runJavaScript(result)
              } catch (error) {
                Logger.error(TAG, "error:" + error)
              }
            }
            break;
          case "reload":
            Logger.debug(TAG, `[RNOH] reload,${JSON.stringify(args)}`)
            if (this.controllerAttached) {
              try {
                this.controller.refresh();
              } catch (error) {
                Logger.error(TAG, "error: " + error)
              }
            }
            break
          case "goBack":
            Logger.debug(TAG, `[RNOH] goBack,${JSON.stringify(args)}`)
            if (this.controllerAttached) {
              try {
                this.controller.backward();
              } catch (error) {
                Logger.error(TAG, "error: " + error)
              }
            }
            break
          case "goForward":
            Logger.debug(TAG, `[RNOH] goForward,${JSON.stringify(args)}`)
            if (this.controllerAttached) {
              try {
                this.controller.forward();
              } catch (error) {
                Logger.error(TAG, "error: " + error)
              }
            }
            break
          case "requestFocus":
            Logger.debug(TAG, `[RNOH] requestFocus,${JSON.stringify(args)}`)
            if (this.controllerAttached) {
              try {
                this.controller.requestFocus();
              } catch (error) {
                Logger.error(TAG, "error: " + error)
              }
            }
            break
          case "clearCache":
            Logger.debug(TAG, `[RNOH] clearCache,${JSON.stringify(args)}`)
            if (this.controllerAttached) {
              try {
                const removeFlag = !!args[0] === true;
                this.controller.removeCache(removeFlag);
              } catch (error) {
                Logger.error(TAG, "error: " + error)
              }
            }
            break
          case "clearHistory":
            Logger.debug(TAG, `[RNOH] clearHistory,${JSON.stringify(args)}`)
            if (this.controllerAttached) {
              try {
                this.controller.clearHistory();
              } catch (error) {
                Logger.error(TAG, "error: " + error)
              }
            }
            break
          default:
            break
        }
      });
  }

  onLoadingStart() {
    this.eventEmitter!.emit('loadingStart', {
      url: this.controller.getUrl(),
      loading: this.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      navigationType: "other",
      mainDocumentURL: ""
    })
  }

  onProgressChange() {
    // 修复单页面应用切换路由时 onPageBegin 未触发的问题
    if (this.controller.getUrl() !== this.url && this.progress < 100 && this.allowPageStartInProgress) {
      this.allowPageStartInProgress = false;
      this.onLoadingStart();
    }
    this.eventEmitter!.emit('loadingProgress', {
      url: this.controller.getUrl(),
      loading: this.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      progress: this.progress / 100
    })
    if (this.progress === 100) {
      this.allowPageStartInProgress = true;
    }
  }

  onLoadingFinish() {
    this.eventEmitter!.emit('loadingFinish', {
      url: this.controller.getUrl(),
      loading: this.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      navigationType: "other",
      mainDocumentURL: ""
    })
  }

  onLoadingError(code: number, description: string) {
    this.eventEmitter!.emit('loadingError', {
      url: this.controller.getUrl(),
      loading: false,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      domain: "",
      code: code,
      description: description
    })
  }

  onHttpError(code: number,description: string) {
    this.eventEmitter!.emit('httpError', {
      url: this.controller.getUrl(),
      loading: false,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      description: description,
      statusCode: code
    })
  }

  onShouldStartLoadWithRequest() {
    this.eventEmitter!.emit('shouldStartLoadWithRequest', {
      url: this.controller.getUrl(),
      loading: this.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      navigationType: "other",
      mainDocumentURL: "",
      isTopFrame: false
    })
  }

  onShouldStartLoadCallFunction(lockIdentifier: number, data: WebResourceRequest) {
    this.eventEmitter!.emit("shouldStartLoadWithRequest", {
      url: data.getRequestUrl(),
      loading: this.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: lockIdentifier,
      navigationType: "other",
      mainDocumentURL: "",
      isTopFrame: data.isMainFrame()
    })
  }

  runInjectedJavaScript() {
    let injectedJS = this.descriptorWrapper.props.injectedJavaScript
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
          value: '确定',
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
          value: '确定',
          action: () => event.result.handleConfirm()
        },
        cancel: () => event.result.handleCancel(),
        primaryButton: {
          value: '取消',
          action: () => event.result.handleCancel()
        },
      })
    }
    return true
  }

  build() {
    Stack() {
      Web({ src: this.source.uri, controller: this.controller, renderMode: this.renderMode })
        .width(this.webviewWidth)
        .height(this.webviewHeight)
        .constraintSize({ minHeight: 1 })
        .overScrollMode(this.overScrollMode)
        .backgroundColor(Color.Transparent)
        .javaScriptAccess(this.javaScriptEnable)
        .javaScriptOnDocumentStart(this.injectedJavaScriptBeforeContentLoaded)
        .horizontalScrollBarAccess(this.descriptorWrapper.props.showsHorizontalScrollIndicator)
        .verticalScrollBarAccess(this.descriptorWrapper.props.showsVerticalScrollIndicator)
        .overviewModeAccess(this.descriptorWrapper.props.scalesPageToFit)
        .textZoomRatio(this.descriptorWrapper.props.textZoom)
        .cacheMode(this.cacheMode)
        .domStorageAccess(this.descriptorWrapper.props.domStorageEnabled)
        .zoomAccess(this.descriptorWrapper.props.scalesPageToFit)
        .overScrollMode(this.overScrollMode)
        .onProgressChange((event) => {
          if (event) {
            this.progress = event.newProgress
            this.onProgressChange()
          }
        })
        .nestedScroll({
          scrollForward: this.nestedScroll,
          scrollBackward: this.nestedScroll,
        })
        .onPageBegin(() => {
          this.onLoadingStart()
          this.controller.setScrollable(this.scrollEnabled)
        })
        .onPageEnd(() => {
          Logger.debug(TAG, "[RNOH] onPageEnd")
          this.runInjectedJavaScript()
          this.onLoadingFinish()
        })
        .onErrorReceive((event) => {
          if (event) {
            let errorInfo: string = event.error.getErrorInfo();
            let errorCode: number = event.error.getErrorCode();
            if (!event.request.isMainFrame()) {
              Logger.debug(TAG, "[RNOH] ERR_INTERNET_DISCONNECTED:OR ERR_CACHE_MISS")
              return
            }
            Logger.debug(TAG, "[RNOH] errorInfo:" + errorInfo)
            Logger.debug(TAG, "[RNOH] errorCode:" + errorCode)
            this.onLoadingError(errorCode, errorInfo)
          }
        })
        .onHttpErrorReceive((event) => {
          if (event) {
            let errorInfo: string = event.response.getResponseData();
            let code: number = event.response.getResponseCode()
            Logger.debug(TAG, "[RNOH] errorInfo:" + errorInfo)
            this.onHttpError(code,errorInfo)
          }
        })
        .onLoadIntercept((event) => {
          if (!this.descriptorWrapper.props.shouldStartLoadWithRequestEnabled) {
            Logger.debug(TAG,
              "[RNOH]:shouldStartLoadWithRequestEnabled:" + this.descriptorWrapper.props.shouldStartLoadWithRequestEnabled)
            return false
          }
          if (this.source.html != undefined && this.source.html != '') {
            Logger.debug(TAG, "[RNOH]: load html not intercept")
            return false;
          }
          if (event.data.getRequestUrl() == this.source.uri || this.requestUrl != "") {
            Logger.debug(TAG, "[RNOH] first load not intercept")
            this.requestUrl = ""
            return false
          }
          this.requestUrl = event.data.getRequestUrl()
          let lockIdentifier = ShouldRequestUrl.getNewData();
          this.lockIdentifier = lockIdentifier
          Logger.debug(TAG, "[RNOH]:lockIdentifier:" + lockIdentifier)
          ShouldRequestUrl.setCallBack(lockIdentifier, () => {
            let data: CallbackState = ShouldRequestUrl.getValue(this.lockIdentifier);
            let should: boolean = data == CallbackState.SHOULD_OVERRIDE
            Logger.debug(TAG, "[RNOH] should:" + should)
            ShouldRequestUrl.removeData(this.lockIdentifier)
            this.lockIdentifier = ""
            if (!should) {
              this.controller.loadUrl(this.requestUrl)
            } else {
              this.requestUrl = ""
            }
          })
          this.onShouldStartLoadCallFunction(Number(this.lockIdentifier), event.data)
          return true
        })
        .onControllerAttached(() => {
          this.controllerAttached = true;
          Logger.debug(TAG, "[RNOH] onControllerAttached")
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
            let header = this.source.headers;
            if (header != undefined) {
              let headers: Array<webview.WebHeader> = [];
              header.forEach(item => {
                if (item.name && item.value) {
                  headers.push({ headerKey: item.name, headerValue: item.value })
                }
              })
              this.controller.loadUrl(uri, headers);
            }
          }
          if (!this.hasRegisterJavaScriptProxy) {
            this.registerPostMessage()
          }
          try {
            // 修复一些页面下无法将鸿蒙userAgent识别为手机的问题
            let userAgent = this.controller.getUserAgent() + ' iPhone';
            this.controller.setCustomUserAgent(userAgent);

          } catch (error) {
            Logger.error(TAG, "setUA error: " + error)
          }
        })
        .onAlert((event) => this.onJavascriptAlert(event))
        .onConfirm((event) => this.onJavascriptConfirm(event))
    }
    .width(this.webviewWidth)
    .height(this.webviewHeight)
    .position({ x: this.descriptorWrapper.positionRelativeToParent.x, y: this.descriptorWrapper.positionRelativeToParent.y })
  }
}
