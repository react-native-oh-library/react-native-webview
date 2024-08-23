import { Descriptor, ViewBaseProps } from '@rnoh/react-native-openharmony'

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

export interface AlertEvent {
  url: string;
  message: string;
  result: JsResult;
}

export const TAG = "WebView"

export const WEB_VIEW = "RNCWebView"

export const JAVASCRIPT_INTERFACE = "ReactNativeWebView";

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
  originWhitelist: Array<string>
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

export enum CACHE_MODE {
  'LOAD_DEFAULT' = 'LOAD_DEFAULT',
  'LOAD_CACHE_ELSE_NETWORK' = 'LOAD_CACHE_ELSE_NETWORK',
  'LOAD_NO_CACHE' = 'LOAD_NO_CACHE',
  'LOAD_CACHE_ONLY' = 'LOAD_CACHE_ONLY',
}

export enum COMMAND_NAME {
  INJECTJAVASCRIPT = 'injectJavaScript',
  POSTMESSAGE = 'postMessage',
  RELOAD = 'reload',
  GOBACK = 'goBack',
  GOFORWARD = 'goForward',
  REQUESTFOCUS = 'requestFocus',
  CLEARCACHE = 'clearCache',
  CLEARHISTORY = 'clearHistory',
  STOPLOADING = 'stopLoading',
  LOADURL='loadUrl'
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


export const ZERO: number = 0

export const EIGHT: number = 8;

export const ONE_HUNDRED: number = 100

export interface ProgressInterface {
  progress: number;
}

export interface LoadingErrorInterface {
  code: number,
  description: string
}

export interface ScrollInterface {
  x: number,
  y: number
}

export enum WebViewOverScrollMode {
  ALWAYS = "always",
  NEVER = "never"
}