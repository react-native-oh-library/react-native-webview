// 创建NodeController
// common.ets
import { UIContext } from '@ohos.arkui.UIContext';
import web_webview from '@ohos.web.webview'
import { NodeController, BuilderNode, Size, FrameNode } from '@ohos.arkui.node';
import { WebViewViewDescriptor } from './WebView'
import Logger from './Logger'

const MAX_WEB_NODE_COUNT = 10;
const TAG = "Common";

export interface onProgressChangeEvent {
  newProgress: number;
}

export interface onErrorReceiveEvent {
  request: WebResourceRequest;
  error: WebResourceError;
}

export interface onLoadInterceptEvent {
  data: WebResourceRequest;
}

// @Builder中为动态组件的具体组件内容
// Data为入参封装类
export class Data {
  controller: WebviewController = new web_webview.WebviewController();
  descriptor: WebViewViewDescriptor | undefined = undefined
  cacheMode: CacheMode = CacheMode.Default
  onProgressChange?: (event?: onProgressChangeEvent) => void = () => {
  }
  onPageEnd?: () => void = () => {
  }
  onErrorReceive?: (event?: onErrorReceiveEvent) => void = () => {
  }
  onLoadIntercept?: (event?: onLoadInterceptEvent) => boolean = () => false
}

@Builder
function WebBuilder(data: Data) {
  Web({ src: "", controller: data.controller, renderMode: RenderMode.SYNC_RENDER })
    .width(data.descriptor?.layoutMetrics.frame.size.width ?? 0)
    .height(data.descriptor?.layoutMetrics.frame.size.height ?? 0)
    .constraintSize({ minHeight: 1 })
    .backgroundColor(Color.Transparent)
    .javaScriptAccess(data.descriptor?.props.javaScriptEnabled)
    .horizontalScrollBarAccess(data.descriptor?.props.showsHorizontalScrollIndicator)
    .verticalScrollBarAccess(data.descriptor?.props.showsVerticalScrollIndicator)
    .overviewModeAccess(data.descriptor?.props.scalesPageToFit)
    .textZoomRatio(data.descriptor?.props.textZoom)
    .cacheMode(data.cacheMode)
    .domStorageAccess(data.descriptor?.props.domStorageEnabled)
    .zoomAccess(data.descriptor?.props.scalesPageToFit)
    .overScrollMode(OverScrollMode.NEVER)
    .onProgressChange(
      (e: onProgressChangeEvent) => {
        Logger.debug(TAG, "web onProgressChange")
        data.onProgressChange?.(e)
      }
    )
    .onPageEnd(
      (e) => {
        Logger.debug(TAG, "web onPageEnd")
        data.onPageEnd?.()
      }
    )
    .onErrorReceive((e: onErrorReceiveEvent) => {
      Logger.debug(TAG, "web onErrorReceive")
      data.onErrorReceive?.(e)
    }
    )
    .onLoadIntercept((e: onLoadInterceptEvent) => {
      Logger.debug(TAG, "web onErrorReceive")
      return data.onLoadIntercept?.(e)
    })
}

let wrap = wrapBuilder<Data[]>(WebBuilder);

// 用于控制和反馈对应的NodeContainer上的节点的行为，需要与NodeContainer一起使用
export class myNodeController extends NodeController {
  private rootnode: BuilderNode<Data[]> | null = null;
  private isMounted = false;
  private id: string = "1";

  // 必须要重写的方法，用于构建节点数、返回节点挂载在对应NodeContainer中
  // 在对应NodeContainer创建的时候调用、或者通过rebuild方法调用刷新
  makeNode(uiContext: UIContext): FrameNode | null {
    Logger.debug(" uicontext is undifined : " + (uiContext === undefined));
    if (this.rootnode != null) {
      // 返回FrameNode节点
      return this.rootnode.getFrameNode();
    }
    // 返回null控制动态组件脱离绑定节点
    return null;
  }

  // 当布局大小发生变化时进行回调
  aboutToResize(size: Size) {
    Logger.debug("aboutToResize width : " + size.width + " height : " + size.height)
  }

  // 当controller对应的NodeContainer在Appear的时候进行回调
  aboutToAppear() {
    this.isMounted = true
    this.getController()?.onActive()
    Logger.debug("ljc aboutToAppear")
  }

  // 当controller对应的NodeContainer在Disappear的时候进行回调
  aboutToDisappear() {
    this.isMounted = false
    this.getController()?.onInactive()
    Logger.debug("ljc aboutToDisappear")
  }

  setMount(isMounted: boolean) {
    this.isMounted = isMounted
  }

  getMount() {
    return this.isMounted;
  }

  getController(): WebviewController | undefined {
    return controllerMap.get(this.id);
  }

  release(): void {
    this.isMounted = false
    this.getController()?.onInactive()
  }

  // 此函数为自定义函数，可作为初始化函数使用
  // 通过UIContext初始化BuilderNode，再通过BuilderNode中的build接口初始化@Builder中的内容
  initWeb(id: string, uiContext: UIContext, control: WebviewController) {
    if (this.rootnode != null) {
      return;
    }
    // 创建节点，需要uiContext
    this.rootnode = new BuilderNode(uiContext)
    // 创建动态Web组件
    this.rootnode.build(wrap, {
      controller: control,
      descriptor: null,
      cacheMode: CacheMode.Default,
      onProgressChange: () => {
      },
      onPageEnd: () => {
      },
      onErrorReceive: () => {
      },
      onLoadIntercept: () => false
    })
    this.id = id
  }

  updateNode(data: Data) {
    this.rootnode?.update(data)
    Logger.debug(TAG, "updateNode")
  }
}

// 创建Map保存所需要的NodeController
let NodeMap: Map<string, myNodeController | undefined> = new Map();
// 创建Map保存所需要的WebViewController
let controllerMap: Map<string, WebviewController | undefined> = new Map();

// 初始化需要UIContext 需在Ability获取
export const createNWeb = (uiContext: UIContext, count: number) => {
  let nodeMapSize = NodeMap.size
  while (nodeMapSize < count && nodeMapSize < MAX_WEB_NODE_COUNT) {
    let id = (nodeMapSize + 1).toString();
    // 创建NodeController
    let baseNode = new myNodeController();
    let controller = new web_webview.WebviewController();
    // 初始化自定义Web组件
    baseNode.initWeb(id, uiContext, controller);
    controllerMap.set(id, controller)
    NodeMap.set(id, baseNode);
    nodeMapSize = NodeMap.size
  }
  if (nodeMapSize === MAX_WEB_NODE_COUNT && count > MAX_WEB_NODE_COUNT) {
    Logger.warn("Common", "The pre-created web node count has reached the maximum limit")
  }
}

// 自定义获取NodeController接口
export const getNWeb = (id: string): myNodeController | undefined => {
  return NodeMap.get(id);
}

export const getFreeWebId = (): string | undefined => {
  let webId: string | undefined;
  NodeMap.forEach((nodeController, id) => {
    if (!nodeController?.getMount() && !webId) {
      nodeController?.setMount(true)
      controllerMap.get(id)?.onActive()
      webId = id;
      return;
    }
  })
  return webId;
}

