import { TurboModule } from '@rnoh/react-native-openharmony/ts';
import { TM } from '@rnoh/react-native-openharmony/generated/ts';
import Logger from './Logger';

const TAG = "WebViewTurboModule"

export class WebViewTurboModule extends TurboModule implements TM.RNCWebViewModule.Spec {
  private loadCallbackMap : Map<number,()=> void> = new Map();

  isFileUploadSupported(): Promise<boolean> {
    return Promise.resolve(true)
  }

  shouldStartLoadWithLockIdentifier(shouldStart: boolean, lockIdentifier: number): void {
    Logger.debug(TAG,`shouldStartLoadWithLockIdentifier shouldStart:${shouldStart},lockIdentifier:${lockIdentifier}`)
    if (shouldStart) {
      this.callLoadFunction(lockIdentifier)
    }else {
      this.clearLoadFunction(lockIdentifier)
    }
  }

  setLoadCallback(lockIdentifier:number, cb: ()=> void) {
    this.loadCallbackMap.set(lockIdentifier,cb)
  }

  callLoadFunction(lockIdentifier:number){
    Logger.debug(TAG,`callLoadFunction function:${JSON.stringify(this.loadCallbackMap.get(lockIdentifier))}`)
    this.loadCallbackMap.get(lockIdentifier)?.()
    this.clearLoadFunction(lockIdentifier)
  }

  clearLoadFunction(lockIdentifier:number){
    Logger.debug(TAG,`clearLoadFunction lockIdentifier:${lockIdentifier} `)
    this.loadCallbackMap.delete(lockIdentifier)
  }
}