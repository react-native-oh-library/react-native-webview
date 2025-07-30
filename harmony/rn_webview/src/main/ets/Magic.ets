/**
 * MIT License
 *
 * Copyright (C) 2025 Huawei Device Co., Ltd.
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

import { Descriptor, ViewBaseProps, ViewDescriptorWrapperBase, ViewRawProps } from '@rnoh/react-native-openharmony'

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

export interface WebViewProps extends ViewRawProps {
  width: number
  height: number
  newSource: WebViewNewSource
  javaScriptEnabled: boolean
  injectedJavaScript: string
  messagingEnabled: boolean
  showsHorizontalScrollIndicator: boolean
  showsVerticalScrollIndicator: boolean
  textZoom: number
  cacheEnabled: boolean
  cacheMode: CACHE_MODE
  domStorageEnabled: boolean
  scalesPageToFit: boolean
  messagingModuleName: string
  webviewDebuggingEnabled: boolean
  scrollEnabled: boolean
  incognito: boolean
  userAgent: string
  shouldStartLoadWithRequestEnabled: boolean
  originWhitelist: Array<string>
  thirdPartyCookiesEnabled: boolean
  fraudulentWebsiteWarningEnabled: boolean
  ignoreSilentHardwareSwitch: boolean
  forceDarkOn: boolean
  minimumFontSize: number
  bounces: boolean
  injectedJavaScriptBeforeContentLoaded: string
  overScrollMode: WebViewOverScrollMode,
  mediaPlaybackRequiresUserAction: boolean
  geolocationEnabled: boolean
  applicationNameForUserAgent: string
  pullToRefreshEnabled: boolean
  schemeList: Array<string>
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

interface WebViewState {}

export type WebViewDescriptor = Descriptor<"WebView", ViewBaseProps, WebViewState, WebViewProps>

export class WebViewViewDescriptorWrapper extends ViewDescriptorWrapperBase<"WebView", ViewBaseProps, WebViewState, WebViewProps> {
}


export const ZERO: number = 0

export const EIGHT: number = 8;

export const ONE_HUNDRED: number = 100

export const REFRESH_OFFSET: number = 120

export const MINHEIGHT: number = 1

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
  LOADURL = 'loadUrl'
}

interface RenderExitReasonMessageItem {
  errorDomain: string
  errorDesc: string
}

export const RenderExitReasonMessage = new Map<number, RenderExitReasonMessageItem>()

RenderExitReasonMessage.set(0,
  { errorDomain: 'ProcessAbnormalTermination', errorDesc: "The rendering process exits abnormally." })
RenderExitReasonMessage.set(1,
  { errorDomain: 'ProcessWasKilled', errorDesc: "SIGKILL is received or manually terminated." })
RenderExitReasonMessage.set(2,
  { errorDomain: 'ProcessCrashed', errorDesc: "The rendering process crashes and exits, such as a segment error." })
RenderExitReasonMessage.set(3,
  { errorDomain: 'ProcessOom', errorDesc: "The program is out of memory." })
RenderExitReasonMessage.set(4,
  { errorDomain: 'ProcessExitUnknown', errorDesc: "Other reasons." })

