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

import { Descriptor, RNComponentContext, ViewBaseProps } from '@rnoh/react-native-openharmony';
import webview from '@ohos.web.webview';
import { RNC } from '@rnoh/react-native-openharmony/generated';
import Logger from './Logger';
import { CallbackState, ShouldRequestUrl } from './ShouldRequestUrl';

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
  webviewDebuggingEnabled: boolean
  scrollEnabled: boolean
  incognito: boolean
  userAgent: string
  shouldStartLoadWithRequestEnabled: boolean
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

export enum ShouldStartLoadWithRequestEnabledStatus {
  START = 0,
  END = 1,
}

export enum CACHE_MODE {
  'LOAD_DEFAULT' = 'LOAD_DEFAULT',
  'LOAD_CACHE_ELSE_NETWORK' = 'LOAD_CACHE_ELSE_NETWORK',
  'LOAD_NO_CACHE' = 'LOAD_NO_CACHE',
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

  constructor(url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean,
    lockIdentifier: number, data: string) {
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
  ctx!: RNComponentContext
  tag: number = 0
  source: WebViewNewSource = {
    uri: "",
    method: "",
    body: "",
    html: "",
    baseUrl: ""
  }
  @State descriptor: WebViewViewDescriptor = {} as WebViewViewDescriptor
  html: string | undefined = ""
  url: string | Resource = ""
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
  // nestedScrollFlag: boolean = false;
  renderMode: RenderMode = RenderMode.SYNC_RENDER;
  scrollEnabled = true;
  @State onLoadInterceptStatus: number = ShouldStartLoadWithRequestEnabledStatus.START
  private unregisterDescriptorChangesListener?: () => void = undefined
  private cleanupCommandCallback?: () => void = undefined
  private eventEmitter: RNC.RNCWebView.EventEmitter | undefined = undefined
  private cleanUpCallbacks: (() => void)[] = []
  private descriptorWrapper: RNC.RNCWebView.DescriptorWrapper = {} as RNC.RNCWebView.DescriptorWrapper

  sendEvent<Payload>(eventNmae: string, payload: Payload) {
    this.ctx.rnInstance.emitDeviceEvent(eventNmae, payload)
  }

  aboutToAppear() {
    this.eventEmitter = new RNC.RNCWebView.EventEmitter(this.ctx.rnInstance, this.tag)
    this.onDescriptorWrapperChange(this.ctx.descriptorRegistry.findDescriptorWrapperByTag<RNC.RNCWebView.DescriptorWrapper>(this.tag)!)
    this.cleanUpCallbacks.push(this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (_descriptor, newDescriptorWrapper) => {
        this.onDescriptorWrapperChange(newDescriptorWrapper! as RNC.RNCWebView.DescriptorWrapper)
      }
    ))
    if (this.descriptorWrapper.props.overScrollMode === 'always') {
      this.overScrollMode = OverScrollMode.ALWAYS
    } else if (this.descriptorWrapper.props.overScrollMode === 'never') {
      this.overScrollMode = OverScrollMode.NEVER
    }

    // this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
    //   (newDescriptor) => {
    //     this.descriptor = (newDescriptor as WebViewViewDescriptor)
    //     Logger.debug(TAG, `[RNOH] newDescriptor props uri, ${JSON.stringify(this.descriptor.props.newSource.uri)}`);
    //     this.cacheMode =
    //       this.descriptor.props.cacheEnabled ? this.transCacheMode(this.descriptor.props.cacheMode) : CacheMode.Online;
    //     this.javaScriptEnable = this.descriptor.props.javaScriptEnabled;
    //     this.source = this.descriptor.props.newSource
    //     if (this.html != "" && this.html != this.source.html) {
    //       Logger.debug(TAG, "[RNOH] html is update")
    //       this.html = this.source.html
    //       if (this.controllerAttached) {
    //         try {
    //           this.controller.loadData(
    //             this.source.html,
    //             "text/html",
    //             "UTF-8",
    //             this.source.baseUrl,
    //             " "
    //           );
    //         } catch (error) {
    //           Logger.error(TAG, "error: " + error)
    //         }
    //       }
    //     } else if (this.source.uri != "" && this.url != this.source.uri) {
    //       Logger.debug(TAG, `[RNOH] newDescriptor props update uri: ` + this.source.uri);
    //       this.url = this.source.uri
    //       if (this.controllerAttached) {
    //         this.controller.loadUrl(this.descriptor.props.newSource.uri)
    //       }
    //     }
    // })
    // webview.WebviewController.setWebDebuggingAccess(this.descriptor.props.webviewDebuggingEnabled)
    this.scrollEnabled = this.descriptorWrapper.props.scrollEnabled;
    this.javaScriptEnable = this.descriptorWrapper.props.javaScriptEnabled;
    this.cacheMode =
      this.descriptorWrapper.props.cacheEnabled ?
      this.transCacheMode(this.descriptorWrapper.props.cacheMode as CACHE_MODE) : CacheMode.Online;
    this.source = this.descriptorWrapper.props.newSource
    this.html = this.source.html
    if (this.source.uri && this.source.uri.toString().startsWith("asset://")) {
      this.source.uri = $rawfile(this.source.uri.toString().replace("asset://", this.ctx.rnInstance.getAssetsDest()));
    }
    this.url = this.source.uri as string;
    // this.nestedScrollFlag = this.descriptor.props.nestedScrollEnabled;
    // nestedScrollEnabled true表示可嵌套滚动，不需要自适应和web统一渲染，默认是false
    // this.renderMode = this.nestedScrollFlag?RenderMode.ASYNC_RENDER:RenderMode.SYNC_RENDER
    this.overScrollMode = this.descriptorWrapper.props.bounces ? OverScrollMode.ALWAYS : OverScrollMode.NEVER
    this.registerCommandCallback()
    if (this.hasIncognito()) {
      this.cacheMode = CacheMode.Online;
      webview.WebCookieManager.putAcceptCookieEnabled(false);
    }
    setTimeout(() => {
      console.log('descriptorWrapper===>' + JSON.stringify(this.descriptorWrapper.props))
    }, 0)
  }

  hasIncognito(): boolean {
    return this.descriptorWrapper.props.incognito && this.descriptorWrapper.props.incognito === true
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
      this.controller.deleteJavaScriptRegister(JAVASCRIPT_INTERFACE)
      this.controller.refresh()
      this.hasRegisterJavaScriptProxy = false
      if (this.hasIncognito()) {
        this.controller.clearHistory()
      }
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

  onHttpError(code: number, description: string) {
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

  build() {
    //RNViewBase({ ctx: this.ctx, tag: this.tag }) {
    Stack() {
      Web({ src: this.source.uri, controller: this.controller, renderMode: this.renderMode })
        .width(this.descriptorWrapper.width)
        .height(this.descriptorWrapper.height)
        .constraintSize({ minHeight: 1 })
        .overScrollMode(this.overScrollMode)
        .backgroundColor(Color.Transparent)
        .javaScriptAccess(this.javaScriptEnable)
        .horizontalScrollBarAccess(this.descriptorWrapper.props.showsHorizontalScrollIndicator)
        .verticalScrollBarAccess(this.descriptorWrapper.props.showsVerticalScrollIndicator)
        .overviewModeAccess(this.descriptorWrapper.props.scalesPageToFit)
        .textZoomRatio(this.descriptorWrapper.props.textZoom)
        .cacheMode(this.cacheMode)
        .domStorageAccess(this.descriptorWrapper.props.domStorageEnabled)
        .zoomAccess(this.descriptorWrapper.props.scalesPageToFit)// nestedScrollFlag 为true 表示可以在嵌套滚动中，web自己能滚动
        .overScrollMode(this.overScrollMode)// .layoutMode(this.nestedScrollFlag ? WebLayoutMode.NONE : WebLayoutMode.FIT_CONTENT)
          // .userAgent(this.descriptorWrapper.props.userAgent ? this.descriptorWrapper.props.userAgent :
          //   '')// .nestedScroll(this.nestedScrollFlag ? {
          //   scrollForward: NestedScrollMode.SELF_ONLY,
          //   scrollBackward: NestedScrollMode.SELF_ONLY
          // } : { scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
          // .overScrollMode(OverScrollMode.NEVER)
          // .onSizeChange((event)=>{
          //   Logger.debug(TAG, "[RNOH] event width: " + event.width + "[RNOH] event height: " + event.height)
          // })
        .onProgressChange((event) => {
          console.log('onProgressChangeonProgressChange====>' + JSON.stringify(event))
          if (event) {
            this.progress = event.newProgress
            this.sendEvent('onLoadProgress', event.newProgress as number)
          }
        })
        .onScroll((event) => {
          if (event) {
            this.sendEvent('onScroll', event)
          }
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
            Logger.debug(TAG, "[RNOH] errorInfo:" + errorInfo)
            Logger.debug(TAG, "[RNOH] errorCode:" + errorCode)
            this.onLoadingError(errorCode, errorInfo)
          }
        })
        .onHttpErrorReceive((event) => {
          console.log('onHttpErrorReceiveevent', event)
          if (event) {
            let errorInfo: string = event.response.getResponseData();
            let code: number = event.response.getResponseCode()
            console.log('onHttpErrorReceive', errorInfo)
            Logger.debug(TAG, "[RNOH] errorInfo:" + errorInfo)
            this.onHttpError(code, errorInfo)
          }
        })
        .onLoadIntercept((event) => {
          if (event) {
            if (this.onLoadInterceptStatus === ShouldStartLoadWithRequestEnabledStatus.START) {
              this.sendEvent('onLoadIntercept', JSON.stringify({
                url: event.data.getRequestUrl(),
                loading: this.progress != 100,
                title: this.controller.getTitle(),
                canGoBack: this.controller.accessBackward(),
                canGoForward: this.controller.accessForward(),
                lockIdentifier: 11,
                navigationType: "other",
                mainDocumentURL: "",
                isTopFrame: event.data.isMainFrame(),
                status: this.onLoadInterceptStatus
              }))
              this.onLoadInterceptStatus = ShouldStartLoadWithRequestEnabledStatus.END
              setTimeout(() => {
                if (this.descriptorWrapper.props.shouldStartLoadWithRequestEnabled) {
                  this.controller.refresh()
                }
              })
            }
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
          if (this.descriptorWrapper.props.userAgent) {
            try {
              let userAgent = this.controller.getUserAgent() + this.descriptorWrapper.props.userAgent;
              this.controller.setCustomUserAgent(userAgent);
            } catch (error) {
              console.error(`ErrorCode: ${error.code},  Message: ${error.message}, userAgent: ${this.descriptorWrapper.props.userAgent}`);
            }
          }
        })
    }
    .width(this.descriptorWrapper.width)
    .height(this.descriptorWrapper.height)
    .position({
      x: this.descriptorWrapper.positionRelativeToParent.x,
      y: this.descriptorWrapper.positionRelativeToParent.y
    })
  }

  private onDescriptorWrapperChange(descriptorWrapper: RNC.RNCWebView.DescriptorWrapper) {
    this.descriptorWrapper = descriptorWrapper

    Logger.debug(TAG, `[RNOH] newDescriptor props uri, ${JSON.stringify(this.descriptorWrapper.props.newSource.uri)}`);
    this.cacheMode =
      this.descriptorWrapper.props.cacheEnabled ?
      this.transCacheMode(this.descriptorWrapper.props.cacheMode as CACHE_MODE) : CacheMode.Online;
    this.javaScriptEnable = this.descriptorWrapper.props.javaScriptEnabled;
    this.source = this.descriptorWrapper.props.newSource
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
            result.data = data
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
}