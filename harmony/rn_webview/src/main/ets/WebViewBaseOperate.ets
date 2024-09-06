import { RNC } from '@rnoh/react-native-openharmony/generated/ts'
import { webview } from '@kit.ArkWeb'
import { CACHE_MODE, COMMAND_NAME, ONE_HUNDRED, WebViewEventParams } from './Magic';
import Logger from './Logger';

export const TAG = "WebView"


interface ProgressInterface {
  progress: number;
}

interface CreateWebViewEventInterface {
  type: string;
  progress: number;
}

export class BaseOperate {
  private eventEmitter: RNC.RNCWebView.EventEmitter
  private controller: webview.WebviewController

  constructor(eventEmitter: RNC.RNCWebView.EventEmitter, controller: webview.WebviewController) {
    this.eventEmitter = eventEmitter
    this.controller = controller
  }


  emitProgressChange(params: ProgressInterface) {
    try {
      this.eventEmitter!.emit('loadingProgress', {
        url: this.controller.getUrl(),
        loading: params.progress != ONE_HUNDRED,
        title: this.controller.getTitle(),
        canGoBack: this.controller.accessBackward(),
        canGoForward: this.controller.accessForward(),
        lockIdentifier: 0,
        progress: params.progress / ONE_HUNDRED
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitProgressChange Errorcode: ${error.code}`);
    }
  }

  emitLoadingStart(params: ProgressInterface) {
    try {
      this.eventEmitter!.emit('loadingStart', {
        url: this.controller.getUrl(),
        loading: params.progress != ONE_HUNDRED,
        title: this.controller.getTitle(),
        canGoBack: this.controller.accessBackward(),
        canGoForward: this.controller.accessForward(),
        lockIdentifier: 0,
        navigationType: "other",
        mainDocumentURL: ""
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitLoadingStart Errorcode: ${error.code}`);
    }
  }

  emitLoadingFinish(params: ProgressInterface) {
    try {
      this.eventEmitter!.emit('loadingFinish', {
        url: this.controller.getUrl(),
        loading: params.progress != ONE_HUNDRED,
        title: this.controller.getTitle(),
        canGoBack: this.controller.accessBackward(),
        canGoForward: this.controller.accessForward(),
        lockIdentifier: 0,
        navigationType: "other",
        mainDocumentURL: ""
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitLoadingFinish Errorcode: ${error.code}`);
    }
  }

  emitLoadingError(event: OnErrorReceiveEvent) {
    try {
      if (!event.request.isMainFrame()) {
        Logger.debug(TAG, "[RNOH] Not Main Frame Error");
        return;
      }
      this.eventEmitter!.emit('loadingError', {
        url: this.controller.getUrl(),
        loading: false,
        title: this.controller.getTitle(),
        canGoBack: this.controller.accessBackward(),
        canGoForward: this.controller.accessForward(),
        lockIdentifier: 0,
        domain: "",
        code: event.error.getErrorCode(),
        description: event.error.getErrorInfo()
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitLoadingError Errorcode: ${error.code}`);
    }
  }

  emitHttpError(event: OnHttpErrorReceiveEvent) {
    try {
      this.eventEmitter!.emit('httpError', {
        url: this.controller.getUrl(),
        loading: false,
        title: this.controller.getTitle(),
        canGoBack: this.controller.accessBackward(),
        canGoForward: this.controller.accessForward(),
        lockIdentifier: 0,
        description: event.response.getResponseData(),
        statusCode: event.response.getResponseCode()
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitHttpError Errorcode: ${error.code}`);
    }
  }

  emitScroll(event: OnScrollEvent) {
    try {
      this.eventEmitter!.emit('scroll', {
        contentInset: {
          bottom: 0,
          left: 0,
          right: 0,
          top: 0
        },
        contentOffset: { y: event.yOffset, x: event.xOffset },
        contentSize: { height: 0, width: 0 },
        layoutMeasurement: { height: 0, width: 0 }
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitScroll Errorcode: ${error.code}`);
    }
  }

  emitShouldStartLoadWithRequest(params: ProgressInterface) {
    try {
      this.eventEmitter!.emit('shouldStartLoadWithRequest', {
        url: this.controller.getUrl(),
        loading: params.progress != ONE_HUNDRED,
        title: this.controller.getTitle(),
        canGoBack: this.controller.accessBackward(),
        canGoForward: this.controller.accessForward(),
        lockIdentifier: 0,
        navigationType: "other",
        mainDocumentURL: "",
        isTopFrame: false
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitShouldStartLoadWithRequest Errorcode: ${error.code}`);
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

  createWebViewEvent(param: CreateWebViewEventInterface): WebViewEventParams {
    let result: WebViewEventParams = new WebViewEventParams(param.type);
    result.loading = param.progress != ONE_HUNDRED
    try {
      result.url = this.controller.getUrl();
      result.title = this.controller.getTitle();
      result.canGoBack = this.controller.accessBackward();
      result.canGoForward = this.controller.accessForward();
    } catch (error) {
      result.url = "";
      result.title = "";
      result.canGoBack = false;
      result.canGoForward = false;
    }
    return result;
  }

  ignoreSilentHardwareSwitchMethods(ignoreSilentHardwareSwitch: boolean) {
    this.controller.setAudioMuted(!ignoreSilentHardwareSwitch)
  }

  setCustomUserAgent(customUserAgent?: string, applicationNameForUserAgent?: string): void {
    try {
      if (customUserAgent) {
        let userAgent: string = customUserAgent;
        this.controller.setCustomUserAgent(userAgent);
      }
      if (applicationNameForUserAgent) {
        this.controller.setCustomUserAgent(`${this.controller.getUserAgent()}${applicationNameForUserAgent}`);
      }
    } catch (error) {
      Logger.debug(TAG,
        `[RNOH] setCustomUserAgent ErrorCode: ${error.code}, userAgent: ${customUserAgent}`);
    }
  }

  injectJavaScript(args: string[]) {
    try {
      this.controller.runJavaScript("(function() {\n" + args[0] + ";\n})();")
    } catch (error) {
      Logger.error(TAG, `[RNOH] injectJavaScript Errorcode: ${error.code}`);
    }
  }

  postMessage(args: string[]) {
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
    try {
      this.controller.runJavaScript(result)
    } catch (error) {
      Logger.error(TAG, `[RNOH] postMessage Errorcode: ${error.code}`);
    }
  }

  reload() {
    try {
      this.controller.refresh();
    } catch (error) {
      Logger.error(TAG, `[RNOH] reload Errorcode: ${error.code}`);
    }
  }

  goBack() {
    try {
      this.controller.backward();
    } catch (error) {
      Logger.error(TAG, `[RNOH] goBack Errorcode: ${error.code}`);
    }
  }

  goForward() {
    try {
      this.controller.forward();
    } catch (error) {
      Logger.error(TAG, `[RNOH] goForward Errorcode: ${error.code}`);
    }
  }

  requestFocus() {
    try {
      this.controller.requestFocus();
    } catch (error) {
      Logger.error(TAG, `[RNOH] requestFocus Errorcode: ${error.code}`);
    }
  }

  clearCache(args: string[]) {
    try {
      const removeFlag = !!args[0] === true;
      this.controller.removeCache(removeFlag);
    } catch (error) {
      Logger.error(TAG, `[RNOH] clearCache Errorcode: ${error.code}`);
    }
  }

  clearHistory() {
    try {
      this.controller.clearHistory();
    } catch (error) {
      Logger.error(TAG, `[RNOH] clearHistory Errorcode: ${error.code}`);
    }
  }

  stopLoading() {
    try {
      this.controller.stop();
    } catch (error) {
      Logger.error(TAG, `[RNOH] stopLoading Errorcode: ${error.code}`);
    }
  }

  loadUrl(args: string[]) {
    try {
      this.controller.loadUrl(args[0]);
    } catch (error) {
      Logger.error(TAG, `[RNOH] loadUrl Errorcode: ${error.code}`);
    }
  }

  registerCommandCallback(commandName: COMMAND_NAME, args: string[]) {
    switch (commandName) {
      case COMMAND_NAME.INJECTJAVASCRIPT:
        this.injectJavaScript(args)
        break
      case COMMAND_NAME.POSTMESSAGE:
        this.postMessage(args)
        break
      case COMMAND_NAME.RELOAD:
        this.reload()
        break
      case COMMAND_NAME.GOBACK:
        this.goBack()
        break
      case COMMAND_NAME.GOFORWARD:
        this.goForward()
        break
      case COMMAND_NAME.REQUESTFOCUS:
        this.requestFocus()
      case COMMAND_NAME.CLEARCACHE:
        this.clearCache(args)
      case COMMAND_NAME.CLEARHISTORY:
        this.clearHistory()
        break
      case COMMAND_NAME.STOPLOADING:
        this.stopLoading()
        break
      case COMMAND_NAME.LOADURL:
        this.loadUrl(args)
        break
      default:
        break
    }
  }

  setOriginWhitelist(uris: string) {
    try {
      this.controller.setUrlTrustList(uris);
    } catch (error) {
      Logger.error(TAG, `[RNOH] setOriginWhitelist Errorcode: ${error.code}`);
    }
  }

  setIncognito() {
    this.controller.clearHistory()
    webview.WebCookieManager.clearAllCookiesSync(true);
    webview.WebCookieManager.clearSessionCookieSync()
    webview.WebStorage.deleteAllData();
  }

  static setThirdPartyCookiesEnabled(status: boolean) {
    try {
      webview.WebCookieManager.putAcceptThirdPartyCookieEnabled(status);
    } catch (error) {
      Logger.error(TAG, `[RNOH] setThirdPartyCookiesEnabled Errorcode: ${error.code}`);
    }
  }

  setFraudulentWebsiteWarningEnabled(status: boolean) {
    try {
      this.controller.enableSafeBrowsing(status);
    } catch (error) {
      Logger.error(TAG, `[RNOH] setFraudulentWebsiteWarningEnabled Errorcode: ${error.code}`);
    }
  }

  onDownloadStart(event: OnDownloadStartEvent) {
    try {
      this.eventEmitter!.emit('fileDownload', {
        downloadUrl: "event.url"
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] onDownloadStart Errorcode: ${error.code}`);
    }
  }

  onRenderExited(event: OnRenderExitedEvent) {
    try {

    } catch (error) {
      Logger.error(TAG, `[RNOH] onRenderExited Errorcode: ${error.code}`);
    }
  }
}
