/*
 * MIT License
 *
 * Copyright (C) 2023 Huawei Device Co., Ltd.
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

import { Descriptor, ComponentBuilderContext, RNOHContext, ViewBaseProps } from '@rnoh/react-native-openharmony'
import webview from '@ohos.web.webview';
import { CallbackState, ShouldRequestUrl } from './ShouldRequestUrl';
import {
  RNViewBase,
  RNViewBaseAttributeModifier,
  ViewDescriptorWrapperBase,
  RNComponentContext
} from '@rnoh/react-native-openharmony';
import Logger from './Logger'
import { getFreeWebId, getNWeb, Data, onErrorReceiveEvent, onLoadInterceptEvent, onProgressChangeEvent } from './Common'

export class WebViewNewSource {
  uri: string | Resource = ""
  method?: string
  body?: string
  headers?: string
  html?: string
  baseUrl?: string
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
  // nestedScrollEnabled: boolean
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

export type WebViewViewDescriptor = Descriptor<"RNCWebView", WebViewProps>

@Component
export struct WebView {
  ctx!: RNOHContext
  tag: number = 0
  @State descriptor: WebViewViewDescriptor = {} as WebViewViewDescriptor
  @State source: WebViewNewSource = {
    uri: "",
    method: "",
    body: "",
    headers: "",
    html: "",
    baseUrl: ""
  }
  html: string | undefined = ""
  url: string | Resource = ""
  private unregisterDescriptorChangesListener?: () => void = undefined
  private cleanupCommandCallback?: () => void = undefined
  controller: webview.WebviewController = new webview.WebviewController();
  javaScriptEnable: boolean = true
  progress: number = 0
  cacheMode: number = CacheMode.Default
  lockIdentifier: string = "";
  requestUrl: string = "";
  messagingEnabled: boolean = false;
  hasRegisterJavaScriptProxy: boolean = false;
  controllerAttached: boolean = false;
  // nestedScrollFlag: boolean = false;
  renderMode: RenderMode = RenderMode.SYNC_RENDER;
  @State private rnViewAttributeModifier: RNViewBaseAttributeModifier | undefined = undefined
  private webNodeId: string | undefined = undefined

  aboutToAppear() {
    Logger.debug(TAG, `aboutToAppear tag:${this.tag}`)
    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<WebViewViewDescriptor>(this.tag)
    this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.descriptor = (newDescriptor as WebViewViewDescriptor)
        Logger.debug(TAG, "update descriptor height: " + this.descriptor.layoutMetrics.frame.size.height + " width:" +
        this.descriptor.layoutMetrics.frame.size.width)
        this.descriptorChangesCallback()
      }
    )
    webview.WebviewController.setWebDebuggingAccess(this.descriptor.props.webviewDebuggingEnabled)
    this.javaScriptEnable = this.descriptor.props.javaScriptEnabled;
    this.cacheMode =
      this.descriptor.props.cacheEnabled ? this.transCacheMode(this.descriptor.props.cacheMode) : CacheMode.Online;
    this.source = this.descriptor.props.newSource
    this.html = this.source.html
    this.url = this.source.uri;
    this.registerCommandCallback()
    let descriptorWrapper =
      this.ctx.descriptorRegistry.findDescriptorWrapperByTag<ViewDescriptorWrapperBase>(this.descriptor.tag)
    if (!descriptorWrapper || !(descriptorWrapper instanceof ViewDescriptorWrapperBase)) {
      descriptorWrapper = new ViewDescriptorWrapperBase(this.descriptor)
    }
    if (this.ctx instanceof RNComponentContext) {
      this.rnViewAttributeModifier = new RNViewBaseAttributeModifier(descriptorWrapper, this.ctx)
    }
    this.webNodeId = getFreeWebId()
    // 预加载场景无法进入onControllerAttached
    if (this.webNodeId !== undefined) {
      Logger.debug(TAG, `The current component is a preloaded webview. id:${this.webNodeId}`)
      let controller = getNWeb(this.webNodeId)?.getController()
      if (controller) {
        this.controller = controller
        this.controllerAttached = true;
      }
      if (!this.hasRegisterJavaScriptProxy) {
        this.registerPostMessage()
      }
      this.descriptorChangesCallback(true)
    } else {
      Logger.debug(TAG, `The current component is not a preloaded webview`)
    }
  }

  descriptorChangesCallback(isForceUpdate: boolean = false) {
    Logger.debug(TAG,
      `[RNOH] descriptorChangesCallback,tag:${this.tag},props: ${JSON.stringify(this.descriptor.props)}`);
    this.cacheMode =
      this.descriptor.props.cacheEnabled ? this.transCacheMode(this.descriptor.props.cacheMode) : CacheMode.Online;
    this.javaScriptEnable = this.descriptor.props.javaScriptEnabled;
    this.source = this.descriptor.props.newSource
    this.updateNode()

    if ((this.html != "" && this.html != this.source.html) || (isForceUpdate && this.source.html)) {
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
    } else if (this.source.uri != "" && this.url != this.source.uri || (isForceUpdate && this.source.uri)) {
      Logger.debug(TAG, `[RNOH] newDescriptor props update uri: ` + this.source.uri);
      this.url = this.source.uri
      if (this.controllerAttached) {
        this.controller.loadUrl(this.descriptor.props.newSource.uri)
      }
    }
  }

  updateNode() {
    let nodeParams = {
      controller: this.controller,
      cacheMode: this.cacheMode,
      descriptor: this.descriptor,
      onProgressChange: (e: onProgressChangeEvent) => this.onProgressChange(e),
      onPageEnd: () => this.onPageEnd(),
      onErrorReceive: (e: onErrorReceiveEvent) => this.onErrorReceive(e),
      onLoadIntercept: (e: onLoadInterceptEvent) => this.onLoadIntercept(e)
    } as Data
    if (this.webNodeId) {
      getNWeb(this.webNodeId)?.updateNode(nodeParams)
    }
  }

  onProgressChange(event: onProgressChangeEvent): void {
    Logger.debug(TAG, "[RNOH] event progress: " + event)
    if (event) {
      this.progress = event.newProgress
      Logger.debug(TAG, "[RNOH] event progress: " + event.newProgress)
    }
  }

  onPageEnd(): void {
    Logger.debug(TAG, "[RNOH] event onPageEnd ")
    this.runInjectedJavaScript()
    this.onLoadingFinish()
  }

  onErrorReceive(event: onErrorReceiveEvent): void {
    Logger.debug(TAG, "[RNOH] event onErrorReceive ")
    if (event) {
      let errorInfo: string = event.error.getErrorInfo();
      let errorCode: number = event.error.getErrorCode();
      if (errorInfo == "ERR_INTERNET_DISCONNECTED" || errorInfo == "ERR_CACHE_MISS" || !event.request.isMainFrame()) {
        Logger.debug(TAG, "[RNOH] ERR_INTERNET_DISCONNECTED:OR ERR_CACHE_MISS")
        return
      }
      Logger.debug(TAG, "[RNOH] errorInfo:" + errorInfo)
      Logger.debug(TAG, "[RNOH] errorCode:" + errorCode)
      this.onLoadingError(errorCode, errorInfo)
    }
  }

  onLoadIntercept(event: onLoadInterceptEvent): boolean {
    Logger.debug(TAG, "[RNOH]:onLoadIntercept:")

    if (!this.descriptor.props.shouldStartLoadWithRequestEnabled) {
      Logger.debug(TAG,
        "[RNOH]:shouldStartLoadWithRequestEnabled:" + this.descriptor.props.shouldStartLoadWithRequestEnabled)
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
  }

  onControllerAttached(): void {
    Logger.debug(TAG, "[RNOH] onControllerAttached")
    this.controllerAttached = true;
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
      if (header != undefined && header != "") {
        let headers: Array<webview.WebHeader> = [];
        JSON.parse(header, (key: string, value: string) => {
          if (key && value) {
            headers.push({ headerKey: key, headerValue: value })
          }
          return undefined;
        })
        this.controller.loadUrl(uri, headers);
      }
    }
    if (!this.hasRegisterJavaScriptProxy) {
      this.registerPostMessage()
    }
  }

  private registerPostMessage() {
    if (this.messagingEnabled == this.descriptor.props.messagingEnabled) {
      return;
    }
    this.messagingEnabled = this.descriptor.props.messagingEnabled;
    if (this.messagingEnabled) {
      let bridge: RNCWebViewBridge = {
        postMessage: (data: string) => {
          Logger.debug(TAG, `[RNOH] bridge postMessage,tag:${this.tag},message: ${JSON.stringify(data)}`);
          if (this.controller != null) {
            let result: WebViewEventParams = this.createWebViewEvent("onMessage")
            result.data = data
            result.lockIdentifier = 0
            this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, WEB_VIEW, result);
          }
        }
      };
      this.controller.registerJavaScriptProxy(bridge, JAVASCRIPT_INTERFACE, ["postMessage"])
      this.controller.refresh()
      this.hasRegisterJavaScriptProxy = true
      Logger.debug(TAG, `registerJavaScriptProxy finish`)
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
    Logger.debug(TAG, `[RNOH] aboutToDisappear tag:${this.tag}`)
    this.cleanupCommandCallback?.()
    this.unregisterDescriptorChangesListener?.()
    try {
      this.controller.deleteJavaScriptRegister(JAVASCRIPT_INTERFACE)
      this.controller.refresh()
      this.hasRegisterJavaScriptProxy = false
    } catch (error) {
      Logger.error(TAG, `[RNOH]Errorcode: ${error.code}, Message: ${error.message}`);
    }
    // if (this.webNodeId) {
    //   getNWeb(this.webNodeId)?.release()
    // }
  }

  transCacheMode(cacheMode: number): CacheMode {
    let mode = CacheMode.Default
    switch (cacheMode) {
      case 0:
        mode = CacheMode.Default
        break;
      case 1:
        mode = CacheMode.None
        break;
      case 2:
        mode = CacheMode.Online
        break;
      case 3:
        mode = CacheMode.Only
        break;
      default:
        break;
    }
    return mode
  }

  registerCommandCallback() {
    Logger.debug(TAG, `registerCommandCallback `)
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
          default:
            break
        }
      });
  }

  onLoadingFinish() {
    Logger.debug(TAG, `emit onLoadingFinish `)
    this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, WEB_VIEW, {
      type: "onLoadingFinish",
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
    Logger.debug(TAG, `emit onLoadingError `)
    this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, WEB_VIEW, {
      type: "onLoadingError",
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

  onShouldStartLoadWithRequest() {
    Logger.debug(TAG, `emit onShouldStartLoadWithRequest `)
    this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, WEB_VIEW, {
      type: "onShouldStartLoadWithRequest",
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
    Logger.debug(TAG, `emit onShouldStartLoadCallFunction `)
    this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, WEB_VIEW, {
      type: "onShouldStartLoadWithRequest",
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
    Logger.debug(TAG, `runInjectedJavaScript `)
    let injectedJS = this.descriptor.props.injectedJavaScript
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

  build() {
    Stack() {
      if (this.webNodeId) {
        NodeContainer(getNWeb(this.webNodeId))
          .onAppear(() => {
            Logger.debug(TAG, "NodeContainer onAppear")
          })
      } else {
        Web({ src: this.source.uri, controller: this.controller, renderMode: this.renderMode })
          .width(this.descriptor.layoutMetrics.frame.size.width)
          .height(this.descriptor.layoutMetrics.frame.size.height)
          .constraintSize({ minHeight: 1 })
          .backgroundColor(Color.Transparent)
          .javaScriptAccess(this.javaScriptEnable)
          .horizontalScrollBarAccess(this.descriptor.props.showsHorizontalScrollIndicator)
          .verticalScrollBarAccess(this.descriptor.props.showsVerticalScrollIndicator)
          .overviewModeAccess(this.descriptor.props.scalesPageToFit)
          .textZoomRatio(this.descriptor.props.textZoom)
          .cacheMode(this.cacheMode)
          .domStorageAccess(this.descriptor.props.domStorageEnabled)
          .zoomAccess(this.descriptor.props.scalesPageToFit)
          .overScrollMode(OverScrollMode.NEVER)
          .onProgressChange((e: onProgressChangeEvent) => this.onProgressChange(e))
          .onPageEnd(() => this.onPageEnd())
          .onErrorReceive((e: onErrorReceiveEvent) => this.onErrorReceive(e))
          .onLoadIntercept((e) => this.onLoadIntercept(e))
          .onControllerAttached(() => this.onControllerAttached())
      }

    }
    .width(this.descriptor.layoutMetrics.frame.size.width)
    .height(this.descriptor.layoutMetrics.frame.size.height)
    .position({ x: this.descriptor.layoutMetrics.frame.origin.x, y: this.descriptor.layoutMetrics.frame.origin.y })
    .attributeModifier(this.rnViewAttributeModifier)
  }
}