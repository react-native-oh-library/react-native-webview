import { RNC } from '@rnoh/react-native-openharmony/generated/ts'
import { webview } from '@kit.ArkWeb'
import { CACHE_MODE, ONE_HUNDRED, WebViewEventParams } from './Magic';
import Logger from './Logger';

export const TAG = "WebView"


interface ProgressInterface {
  progress: number;
}

interface LoadingErrorInterface {
  code: number;
  description: string
}

interface ScrollInterface {
  x: number;
  y: number
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
      Logger.error(TAG, `[RNOH] emitProgressChange Errorcode: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `[RNOH] emitLoadingStart Errorcode: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `[RNOH] emitLoadingFinish Errorcode: ${JSON.stringify(error)}`);
    }
  }

  emitLoadingError(params: LoadingErrorInterface) {
    try {
      this.eventEmitter!.emit('loadingError', {
        url: this.controller.getUrl(),
        loading: false,
        title: this.controller.getTitle(),
        canGoBack: this.controller.accessBackward(),
        canGoForward: this.controller.accessForward(),
        lockIdentifier: 0,
        domain: "",
        code: params.code,
        description: params.description
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitLoadingError Errorcode: ${JSON.stringify(error)}`);
    }
  }

  emitHttpError(params: LoadingErrorInterface) {
    try {
      this.eventEmitter!.emit('httpError', {
        url: this.controller.getUrl(),
        loading: false,
        title: this.controller.getTitle(),
        canGoBack: this.controller.accessBackward(),
        canGoForward: this.controller.accessForward(),
        lockIdentifier: 0,
        description: params.description,
        statusCode: params.code
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitHttpError Errorcode: ${JSON.stringify(error)}`);
    }
  }

  emitScroll(params: ScrollInterface) {
    try {
      this.eventEmitter!.emit('scroll', {
        contentInset: {
          bottom: 0,
          left: 0,
          right: 0,
          top: 0
        },
        contentOffset: { y: params.y, x: params.x },
        contentSize: { height: 0, width: 0 },
        layoutMeasurement: { height: 0, width: 0 }
      })
    } catch (error) {
      Logger.error(TAG, `[RNOH] emitScroll Errorcode: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `[RNOH] emitShouldStartLoadWithRequest Errorcode: ${JSON.stringify(error)}`);
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

  setCustomUserAgent(customUserAgent?: string): void {
    try {
      if (customUserAgent) {
        let userAgent: string = this.controller.getUserAgent() + ` ${customUserAgent}`;
        this.controller.setCustomUserAgent(userAgent);
      } else {
        // 修复一些页面下无法将鸿蒙userAgent识别为手机的问题
        let userAgent: string = this.controller.getUserAgent() + ' iPhone';
        this.controller.setCustomUserAgent(userAgent);
      }
    } catch (error) {
      Logger.debug(TAG,
        `[RNOH] setCustomUserAgent ErrorCode: ${error.code},  Message: ${error.message}, userAgent: ${customUserAgent}`);
    }
  }
}
