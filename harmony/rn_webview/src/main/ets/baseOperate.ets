import { RNC } from '@rnoh/react-native-openharmony/generated/ts'
import { webview } from '@kit.ArkWeb'
import { CACHE_MODE, ONE_HUNDRED, WebViewEventParams } from './Magic';

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
  static instance: BaseOperate | null = null
  private eventEmitter: RNC.RNCWebView.EventEmitter
  private controller: webview.WebviewController

  constructor(eventEmitter: RNC.RNCWebView.EventEmitter, controller: webview.WebviewController) {
    this.eventEmitter = eventEmitter
    this.controller = controller
  }

  static getInstance(eventEmitter: RNC.RNCWebView.EventEmitter, controller: webview.WebviewController): BaseOperate {
    if (BaseOperate.instance === null) {
      BaseOperate.instance = new BaseOperate(eventEmitter, controller)
    }
    return BaseOperate.instance
  }

  emitProgressChange(params: ProgressInterface) {
    this.eventEmitter!.emit('loadingProgress', {
      url: this.controller.getUrl(),
      loading: params.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      progress: params.progress / 100
    })
  }

  emitLoadingStart(params: ProgressInterface) {
    this.eventEmitter!.emit('loadingStart', {
      url: this.controller.getUrl(),
      loading: params.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      navigationType: "other",
      mainDocumentURL: ""
    })
  }

  emitLoadingFinish(params: ProgressInterface) {
    this.eventEmitter!.emit('loadingFinish', {
      url: this.controller.getUrl(),
      loading: params.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      navigationType: "other",
      mainDocumentURL: ""
    })
  }

  emitLoadingError(params: LoadingErrorInterface) {
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
  }

  emitHttpError(params: LoadingErrorInterface) {
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
  }

  emitScroll(params: ScrollInterface) {
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
  }

  emitShouldStartLoadWithRequest(params: ProgressInterface) {
    this.eventEmitter!.emit('shouldStartLoadWithRequest', {
      url: this.controller.getUrl(),
      loading: params.progress != 100,
      title: this.controller.getTitle(),
      canGoBack: this.controller.accessBackward(),
      canGoForward: this.controller.accessForward(),
      lockIdentifier: 0,
      navigationType: "other",
      mainDocumentURL: "",
      isTopFrame: false
    })
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
}
