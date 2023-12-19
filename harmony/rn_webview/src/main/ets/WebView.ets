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
 
import {
  Descriptor,
  ComponentBuilderContext,
  RNOHContext,
  ViewBaseProps
} from 'rnoh'
import webview from '@ohos.web.webview';
import { CallbackState, ShouldRequestUrl } from './ShouldRequestUrl';
import { RNViewBase } from 'rnoh';
import Logger from './Logger'

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
  @BuilderParam buildCustomComponent: (componentBuilderContext: ComponentBuilderContext) => void
  @State descriptor: WebViewViewDescriptor = {} as WebViewViewDescriptor
  @State source: WebViewNewSource = {uri: "", method: "", body: "", headers: "", html: "", baseUrl: ""}
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

  aboutToAppear() {
    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<WebViewViewDescriptor>(this.tag)
    this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.descriptor = (newDescriptor as WebViewViewDescriptor)
        Logger.debug(TAG, `[RNOH] newDescriptor props uri, ${JSON.stringify(this.descriptor.props.newSource.uri)}`);
        this.cacheMode = this.descriptor.props.cacheEnabled ? this.transCacheMode(this.descriptor.props.cacheMode) : CacheMode.Online;
        this.javaScriptEnable = this.descriptor.props.javaScriptEnabled;
        this.source = this.descriptor.props.newSource
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
          this.url = this.source.uri
          if (this.controllerAttached) {
            this.controller.loadUrl(this.descriptor.props.newSource.uri)
          }
        } else {
          Logger.debug(TAG, `[RNOH] newDescriptor props refresh`);
          if (this.controllerAttached) {
            this.controller.refresh()
          }
        }
      }
    )
    webview.WebviewController.setWebDebuggingAccess(this.descriptor.props.webviewDebuggingEnabled)
    this.javaScriptEnable = this.descriptor.props.javaScriptEnabled;
    this.cacheMode = this.descriptor.props.cacheEnabled ? this.transCacheMode(this.descriptor.props.cacheMode) : CacheMode.Online;
    this.source = this.descriptor.props.newSource
    this.html = this.source.html
    this.url = this.source.uri;
    this.registerCommandCallback()
  }

  private registerPostMessage() {
    if (this.messagingEnabled == this.descriptor.props.messagingEnabled) {
      return;
    }
    this.messagingEnabled = this.descriptor.props.messagingEnabled;
    if (this.messagingEnabled) {
      let bridge: RNCWebViewBridge = {
        postMessage: (data: string) => {
          Logger.debug(TAG, `[RNOH] bridge postMessage,  ${JSON.stringify(data)}`);
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
    try {
      this.controller.deleteJavaScriptRegister(JAVASCRIPT_INTERFACE)
      this.controller.refresh()
      this.hasRegisterJavaScriptProxy = false
    } catch (error) {
      Logger.error(TAG, `[RNOH]Errorcode: ${error.code}, Message: ${error.message}`);
    }
  }

  transCacheMode(cacheMode: number):CacheMode {
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

  registerCommandCallback(){
    this.cleanupCommandCallback = this.ctx.commandDispatcher.registerCommandCallback(
      this.tag,
      (command,args:string[]) => {
        switch (command) {
          case "injectJavaScript":
            Logger.debug(TAG,`[RNOH] injectJavaScript,${JSON.stringify(args)}`)
            if (this.controllerAttached) {
              try {
                this.controller.runJavaScript(args[0])
              } catch (error) {
                Logger.error(TAG, "error: " + error)
              }
            }
            break
          case "postMessage":
            Logger.debug(TAG,`[RNOH] postMessage,${JSON.stringify(args)}`)
            break
          case "reload":
            Logger.debug(TAG,`[RNOH] reload,${JSON.stringify(args)}`)
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
    this.ctx.rnInstance.emitComponentEvent(this.descriptor.tag, WEB_VIEW, {
      type: "onLoadingFinish",
      url: this.controller.getUrl(),
      loading: this.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      navigationType: "other",
      mainDocumentURL: ""})
  }

  onLoadingError(code: number, description: string) {
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
      description: description})
  }

  onShouldStartLoadWithRequest() {
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
      isTopFrame: false})
  }

  onShouldStartLoadCallFunction(lockIdentifier: number, data: WebResourceRequest) {
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
      isTopFrame: data.isMainFrame()})
  }

  runInjectedJavaScript() {
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
    RNViewBase({ ctx: this.ctx, tag: this.tag }) {
      Web({ src: this.source.uri, controller: this.controller })
        .width('100%').height('100%').constraintSize({minHeight:1})
        .backgroundColor(Color.Transparent)
        .javaScriptAccess(this.javaScriptEnable)
        .horizontalScrollBarAccess(this.descriptor.props.showsHorizontalScrollIndicator)
        .verticalScrollBarAccess(this.descriptor.props.showsVerticalScrollIndicator)
        .overviewModeAccess(this.descriptor.props.scalesPageToFit)
        .textZoomRatio(this.descriptor.props.textZoom)
        .cacheMode(this.cacheMode)
        .domStorageAccess(this.descriptor.props.domStorageEnabled)
        .zoomAccess(this.descriptor.props.scalesPageToFit)
        .onProgressChange((event) => {
          if (event) {
            this.progress = event.newProgress
            Logger.debug(TAG, "[RNOH] event progress: " + event.newProgress)
          }
        })
        .onPageEnd(() => {
          Logger.debug(TAG, "[RNOH] onPageEnd")
          this.runInjectedJavaScript()
          this.onLoadingFinish()
        })
        .onErrorReceive((event) => {
          if (event) {
            let errorInfo:string = event.error.getErrorInfo();
            let errorCode:number = event.error.getErrorCode();
            if (errorInfo == "ERR_INTERNET_DISCONNECTED" || errorInfo == "ERR_CACHE_MISS") {
              Logger.debug(TAG,"[RNOH] ERR_INTERNET_DISCONNECTED:OR ERR_CACHE_MISS")
              return
            }
            Logger.debug(TAG,"[RNOH] errorInfo:" + errorInfo)
            Logger.debug(TAG,"[RNOH] errorCode:" + errorCode)
            this.onLoadingError(errorCode,errorInfo)
          }
        })
        .onLoadIntercept((event) => {
          if (!this.descriptor.props.shouldStartLoadWithRequestEnabled) {
            Logger.debug(TAG,"[RNOH]:shouldStartLoadWithRequestEnabled:" + this.descriptor.props.shouldStartLoadWithRequestEnabled)
            return false
          }
          if (this.source.html != undefined && this.source.html != '') {
            Logger.debug(TAG,"[RNOH]: load html not intercept")
            return false;
          }
          if (event.data.getRequestUrl() == this.source.uri || this.requestUrl != "") {
            Logger.debug(TAG,"[RNOH] first load not intercept")
            this.requestUrl = ""
            return false
          }
          this.requestUrl = event.data.getRequestUrl()
          let lockIdentifier = ShouldRequestUrl.getNewData();
          this.lockIdentifier = lockIdentifier
          Logger.debug(TAG,"[RNOH]:lockIdentifier:" + lockIdentifier)
          ShouldRequestUrl.setCallBack(lockIdentifier,() => {
            let data:CallbackState = ShouldRequestUrl.getValue(this.lockIdentifier);
            let should:boolean = data == CallbackState.SHOULD_OVERRIDE
            Logger.debug(TAG,"[RNOH] should:" + should)
            ShouldRequestUrl.removeData(this.lockIdentifier)
            this.lockIdentifier = ""
            if (!should) {
              this.controller.loadUrl(this.requestUrl)
            } else {
              this.requestUrl = ""
            }
          })
          this.onShouldStartLoadCallFunction(Number(this.lockIdentifier),event.data)
          return true
        })
        .onControllerAttached(() => {
          this.controllerAttached = true;
          Logger.debug(TAG,"[RNOH] onControllerAttached")
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
              Logger.error(TAG,"error:" + error)
            }
          } else if(uri != undefined && uri != "") {
            let header = this.source.headers
            if (header != undefined && header != "") {
              let headers:Array<webview.WebHeader> = [];
              JSON.parse(header,(key:string,value:string) => {
                headers.push({headerKey:key,headerValue:value})
              })
              this.controller.loadUrl(uri,headers);
            }
          }
          if (!this.hasRegisterJavaScriptProxy) {
            this.registerPostMessage()
          }
        })
    }
  }
}