import {
  Descriptor as ComponentDescriptor,
  ViewBaseProps,
  ViewRawProps,
  ViewDescriptorWrapperBase,
  ColorValue,
  Color,
  RNInstance,
  Tag,
  RNComponentCommandReceiver,
  ViewPropsSelector,
} from '@rnoh/react-native-openharmony/ts';


export namespace RNCWebView {
  export const NAME = "RNCWebView" as const

  export interface DirectRawProps {
    allowFileAccess?: boolean;
    allowsProtectedMedia?: boolean;
    allowsFullscreenVideo?: boolean;
    androidLayerType?: 'none' | 'software' | 'hardware';
    cacheMode?: 'LOAD_DEFAULT' | 'LOAD_CACHE_ELSE_NETWORK' | 'LOAD_NO_CACHE' | 'LOAD_CACHE_ONLY';
    domStorageEnabled?: boolean;
    downloadingMessage?: string;
    forceDarkOn?: boolean;
    geolocationEnabled?: boolean;
    lackPermissionToDownloadMessage?: string;
    messagingModuleName: string;
    minimumFontSize?: number;
    mixedContentMode?: 'never' | 'always' | 'compatibility';
    nestedScrollEnabled?: boolean;
    overScrollMode?: string;
    saveFormDataDisabled?: boolean;
    scalesPageToFit?: boolean;
    setBuiltInZoomControls?: boolean;
    setDisplayZoomControls?: boolean;
    setSupportMultipleWindows?: boolean;
    textZoom?: number;
    thirdPartyCookiesEnabled?: boolean;
    hasOnScroll?: boolean;
    injectedJavaScriptObject?: string;
    allowingReadAccessToURL?: string;
    allowsBackForwardNavigationGestures?: boolean;
    allowsInlineMediaPlayback?: boolean;
    allowsAirPlayForMediaPlayback?: boolean;
    allowsLinkPreview?: boolean;
    automaticallyAdjustContentInsets?: boolean;
    autoManageStatusBarEnabled?: boolean;
    bounces?: boolean;
    contentInset?: {top?: number, left?: number, bottom?: number, right?: number};
    contentInsetAdjustmentBehavior?: 'never' | 'automatic' | 'scrollableAxes' | 'always';
    contentMode?: 'recommended' | 'mobile' | 'desktop';
    dataDetectorTypes?: 'address' | 'link' | 'calendarEvent' | 'trackingNumber' | 'flightNumber' | 'lookupSuggestion' | 'phoneNumber' | 'all' | 'none'[];
    decelerationRate?: number;
    directionalLockEnabled?: boolean;
    enableApplePay?: boolean;
    hideKeyboardAccessoryView?: boolean;
    keyboardDisplayRequiresUserAction?: boolean;
    limitsNavigationsToAppBoundDomains?: boolean;
    mediaCapturePermissionGrantType?: 'prompt' | 'grant' | 'deny' | 'grantIfSameHostElsePrompt' | 'grantIfSameHostElseDeny';
    pagingEnabled?: boolean;
    pullToRefreshEnabled?: boolean;
    scrollEnabled?: boolean;
    sharedCookiesEnabled?: boolean;
    textInteractionEnabled?: boolean;
    useSharedProcessPool?: boolean;
    menuItems?: {label: string, key: string}[];
    suppressMenuItems?: string[];
    hasOnFileDownload?: boolean;
    fraudulentWebsiteWarningEnabled?: boolean;
    allowFileAccessFromFileURLs?: boolean;
    allowUniversalAccessFromFileURLs?: boolean;
    applicationNameForUserAgent?: string;
    basicAuthCredential?: {username: string, password: string};
    cacheEnabled?: boolean;
    incognito?: boolean;
    injectedJavaScript?: string;
    injectedJavaScriptBeforeContentLoaded?: string;
    injectedJavaScriptForMainFrameOnly?: boolean;
    injectedJavaScriptBeforeContentLoadedForMainFrameOnly?: boolean;
    javaScriptCanOpenWindowsAutomatically?: boolean;
    javaScriptEnabled?: boolean;
    webviewDebuggingEnabled?: boolean;
    mediaPlaybackRequiresUserAction?: boolean;
    messagingEnabled: boolean;
    shouldStartLoadWithRequestEnabled: boolean;
    hasOnOpenWindowEvent?: boolean;
    showsHorizontalScrollIndicator?: boolean;
    showsVerticalScrollIndicator?: boolean;
    newSource: {uri?: string, method?: string, body?: string, headers?: {name: string, value: string}[], html?: string, baseUrl?: string};
    userAgent?: string;
  }

  export interface Props extends ViewBaseProps {}

  export interface State {}

  export interface RawProps extends ViewRawProps, DirectRawProps {}

  export class PropsSelector extends ViewPropsSelector<Props, RawProps> {
    get allowFileAccess() {
      return this.rawProps.allowFileAccess ?? false;
    }

    get allowsProtectedMedia() {
      return this.rawProps.allowsProtectedMedia ?? false;
    }

    get allowsFullscreenVideo() {
      return this.rawProps.allowsFullscreenVideo ?? false;
    }

    get androidLayerType() {
      return this.rawProps.androidLayerType ?? 'none';
    }

    get cacheMode() {
      return this.rawProps.cacheMode ?? 'LOAD_DEFAULT';
    }

    get domStorageEnabled() {
      return this.rawProps.domStorageEnabled ?? false;
    }

    get downloadingMessage() {
      return this.rawProps.downloadingMessage;
    }

    get forceDarkOn() {
      return this.rawProps.forceDarkOn ?? false;
    }

    get geolocationEnabled() {
      return this.rawProps.geolocationEnabled ?? false;
    }

    get lackPermissionToDownloadMessage() {
      return this.rawProps.lackPermissionToDownloadMessage;
    }

    get messagingModuleName() {
      return this.rawProps.messagingModuleName;
    }

    get minimumFontSize() {
      return this.rawProps.minimumFontSize ?? 0;
    }

    get mixedContentMode() {
      return this.rawProps.mixedContentMode ?? 'never';
    }

    get nestedScrollEnabled() {
      return this.rawProps.nestedScrollEnabled ?? false;
    }

    get overScrollMode() {
      return this.rawProps.overScrollMode;
    }

    get saveFormDataDisabled() {
      return this.rawProps.saveFormDataDisabled ?? false;
    }

    get scalesPageToFit() {
      return this.rawProps.scalesPageToFit ?? false;
    }

    get setBuiltInZoomControls() {
      return this.rawProps.setBuiltInZoomControls ?? false;
    }

    get setDisplayZoomControls() {
      return this.rawProps.setDisplayZoomControls ?? false;
    }

    get setSupportMultipleWindows() {
      return this.rawProps.setSupportMultipleWindows ?? false;
    }

    get textZoom() {
      return this.rawProps.textZoom ?? 0;
    }

    get thirdPartyCookiesEnabled() {
      return this.rawProps.thirdPartyCookiesEnabled ?? false;
    }

    get hasOnScroll() {
      return this.rawProps.hasOnScroll ?? false;
    }

    get injectedJavaScriptObject() {
      return this.rawProps.injectedJavaScriptObject;
    }

    get allowingReadAccessToURL() {
      return this.rawProps.allowingReadAccessToURL;
    }

    get allowsBackForwardNavigationGestures() {
      return this.rawProps.allowsBackForwardNavigationGestures ?? false;
    }

    get allowsInlineMediaPlayback() {
      return this.rawProps.allowsInlineMediaPlayback ?? false;
    }

    get allowsAirPlayForMediaPlayback() {
      return this.rawProps.allowsAirPlayForMediaPlayback ?? false;
    }

    get allowsLinkPreview() {
      return this.rawProps.allowsLinkPreview ?? false;
    }

    get automaticallyAdjustContentInsets() {
      return this.rawProps.automaticallyAdjustContentInsets ?? false;
    }

    get autoManageStatusBarEnabled() {
      return this.rawProps.autoManageStatusBarEnabled ?? false;
    }

    get bounces() {
      return this.rawProps.bounces ?? false;
    }

    get contentInset() {
      return this.rawProps.contentInset;
    }

    get contentInsetAdjustmentBehavior() {
      return this.rawProps.contentInsetAdjustmentBehavior ?? 'never';
    }

    get contentMode() {
      return this.rawProps.contentMode ?? 'recommended';
    }

    get dataDetectorTypes() {
      return this.rawProps.dataDetectorTypes;
    }

    get decelerationRate() {
      return this.rawProps.decelerationRate ?? 0;
    }

    get directionalLockEnabled() {
      return this.rawProps.directionalLockEnabled ?? false;
    }

    get enableApplePay() {
      return this.rawProps.enableApplePay ?? false;
    }

    get hideKeyboardAccessoryView() {
      return this.rawProps.hideKeyboardAccessoryView ?? false;
    }

    get keyboardDisplayRequiresUserAction() {
      return this.rawProps.keyboardDisplayRequiresUserAction ?? false;
    }

    get limitsNavigationsToAppBoundDomains() {
      return this.rawProps.limitsNavigationsToAppBoundDomains ?? false;
    }

    get mediaCapturePermissionGrantType() {
      return this.rawProps.mediaCapturePermissionGrantType ?? 'prompt';
    }

    get pagingEnabled() {
      return this.rawProps.pagingEnabled ?? false;
    }

    get pullToRefreshEnabled() {
      return this.rawProps.pullToRefreshEnabled ?? false;
    }

    get scrollEnabled() {
      return this.rawProps.scrollEnabled ?? false;
    }

    get sharedCookiesEnabled() {
      return this.rawProps.sharedCookiesEnabled ?? false;
    }

    get textInteractionEnabled() {
      return this.rawProps.textInteractionEnabled ?? false;
    }

    get useSharedProcessPool() {
      return this.rawProps.useSharedProcessPool ?? false;
    }

    get menuItems() {
      return this.rawProps.menuItems;
    }

    get suppressMenuItems() {
      return this.rawProps.suppressMenuItems;
    }

    get hasOnFileDownload() {
      return this.rawProps.hasOnFileDownload ?? false;
    }

    get fraudulentWebsiteWarningEnabled() {
      return this.rawProps.fraudulentWebsiteWarningEnabled ?? false;
    }

    get allowFileAccessFromFileURLs() {
      return this.rawProps.allowFileAccessFromFileURLs ?? false;
    }

    get allowUniversalAccessFromFileURLs() {
      return this.rawProps.allowUniversalAccessFromFileURLs ?? false;
    }

    get applicationNameForUserAgent() {
      return this.rawProps.applicationNameForUserAgent;
    }

    get basicAuthCredential() {
      return this.rawProps.basicAuthCredential;
    }

    get cacheEnabled() {
      return this.rawProps.cacheEnabled ?? false;
    }

    get incognito() {
      return this.rawProps.incognito ?? false;
    }

    get injectedJavaScript() {
      return this.rawProps.injectedJavaScript;
    }

    get injectedJavaScriptBeforeContentLoaded() {
      return this.rawProps.injectedJavaScriptBeforeContentLoaded;
    }

    get injectedJavaScriptForMainFrameOnly() {
      return this.rawProps.injectedJavaScriptForMainFrameOnly ?? false;
    }

    get injectedJavaScriptBeforeContentLoadedForMainFrameOnly() {
      return this.rawProps.injectedJavaScriptBeforeContentLoadedForMainFrameOnly ?? false;
    }

    get javaScriptCanOpenWindowsAutomatically() {
      return this.rawProps.javaScriptCanOpenWindowsAutomatically ?? false;
    }

    get javaScriptEnabled() {
      return this.rawProps.javaScriptEnabled ?? false;
    }

    get webviewDebuggingEnabled() {
      return this.rawProps.webviewDebuggingEnabled ?? false;
    }

    get mediaPlaybackRequiresUserAction() {
      return this.rawProps.mediaPlaybackRequiresUserAction ?? false;
    }

    get messagingEnabled() {
      return this.rawProps.messagingEnabled ?? false;
    }

    get shouldStartLoadWithRequestEnabled() {
      return this.rawProps.shouldStartLoadWithRequestEnabled ?? false;
    }

    get hasOnOpenWindowEvent() {
      return this.rawProps.hasOnOpenWindowEvent ?? false;
    }

    get showsHorizontalScrollIndicator() {
      return this.rawProps.showsHorizontalScrollIndicator ?? false;
    }

    get showsVerticalScrollIndicator() {
      return this.rawProps.showsVerticalScrollIndicator ?? false;
    }

    get newSource() {
      return this.rawProps.newSource;
    }

    get userAgent() {
      return this.rawProps.userAgent;
    }


  }

  export type Descriptor = ComponentDescriptor<
  typeof NAME,
  Props,
  State,
  RawProps
  >;

  export class DescriptorWrapper extends ViewDescriptorWrapperBase<
  typeof NAME,
  Props,
  State,
  RawProps,
  PropsSelector
  > {
    protected createPropsSelector() {
      return new PropsSelector(this.descriptor.props, this.descriptor.rawProps)
    }
  }

  export interface EventPayloadByName {
    "contentSizeChange": {url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number}
    "renderProcessGone": {didCrash: boolean}
    "contentProcessDidTerminate": {url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number}
    "customMenuSelection": {label: string, key: string, selectedText: string}
    "fileDownload": {downloadUrl: string}
    "loadingError": {url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number, domain?: string, code: number, description: string}
    "loadingFinish": {url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number, navigationType: 'click' | 'formsubmit' | 'backforward' | 'reload' | 'formresubmit' | 'other', mainDocumentURL?: string}
    "loadingProgress": {url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number, progress: number}
    "loadingStart": {url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number, navigationType: 'click' | 'formsubmit' | 'backforward' | 'reload' | 'formresubmit' | 'other', mainDocumentURL?: string}
    "httpError": {url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number, description: string, statusCode: number}
    "message": {url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number, data: string}
    "openWindow": {targetUrl: string}
    "scroll": {contentInset: {bottom: number, left: number, right: number, top: number}, contentOffset: {y: number, x: number}, contentSize: {height: number, width: number}, layoutMeasurement: {height: number, width: number}, targetContentOffset?: {y: number, x: number}, velocity?: {y: number, x: number}, zoomScale?: number, responderIgnoreScroll?: boolean}
    "shouldStartLoadWithRequest": {url: string, loading: boolean, title: string, canGoBack: boolean, canGoForward: boolean, lockIdentifier: number, navigationType: 'click' | 'formsubmit' | 'backforward' | 'reload' | 'formresubmit' | 'other', mainDocumentURL?: string, isTopFrame: boolean}
  }

  export class EventEmitter {
    constructor(private rnInstance: RNInstance, private tag: Tag) {}

    emit<TEventName extends keyof EventPayloadByName>(eventName: TEventName, payload: EventPayloadByName[TEventName]) {
      this.rnInstance.emitComponentEvent(this.tag, eventName, payload)
    }
  }

  export interface CommandArgvByName {
    "goBack": []
    "goForward": []
    "reload": []
    "stopLoading": []
    "injectJavaScript": [string]
    "requestFocus": []
    "postMessage": [string]
    "loadUrl": [string]
    "clearFormData": []
    "clearCache": [boolean]
    "clearHistory": []
  }

  export class CommandReceiver {
    private listenersByCommandName = new Map<string, Set<(...args: any[]) => void>>()
    private cleanUp: (() => void) | undefined = undefined

    constructor(private componentCommandReceiver: RNComponentCommandReceiver, private tag: Tag) {
    }

    subscribe<TCommandName extends keyof CommandArgvByName>(commandName: TCommandName, listener: (argv: CommandArgvByName[TCommandName]) => void) {
      if (!this.listenersByCommandName.has(commandName)) {
        this.listenersByCommandName.set(commandName, new Set())
      }
      this.listenersByCommandName.get(commandName)!.add(listener)
      const hasRegisteredCommandReceiver = !!this.cleanUp
      if (!hasRegisteredCommandReceiver) {
        this.cleanUp = this.componentCommandReceiver.registerCommandCallback(this.tag, (commandName: string, argv: any[]) => {
          if (this.listenersByCommandName.has(commandName)) {
            const listeners = this.listenersByCommandName.get(commandName)!
            listeners.forEach(listener => {
              listener(argv)
            })
          }
        })
      }

      return () => {
        this.listenersByCommandName.get(commandName)?.delete(listener)
        if (this.listenersByCommandName.get(commandName)?.size ?? 0 === 0) {
          this.listenersByCommandName.delete(commandName)
        }
        if (this.listenersByCommandName.size === 0) {
          this.cleanUp?.()
        }
      }
    }
  }

}
