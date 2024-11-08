import { UITurboModule } from '@rnoh/react-native-openharmony/ts';
import { TM } from '@rnoh/react-native-openharmony/generated/ts';

export class WebViewTurboModule extends UITurboModule implements TM.RNCWebViewModule.Spec {
  private loadCallbackMap : Map<number,()=> void> = new Map();

  isFileUploadSupported(): Promise<boolean> {
    return Promise.resolve(true)
  }

  shouldStartLoadWithLockIdentifier(shouldStart: boolean, lockIdentifier: number): void {
    if (shouldStart) {
      this.callLoadFunction(lockIdentifier)
    }else {
      this.loadCallbackMap.delete(lockIdentifier)
    }
  }

  setLoadCallback(tag:number, cb: ()=> void) {
    this.loadCallbackMap.set(tag,cb)
  }

  callLoadFunction(tag:number){
    this.loadCallbackMap.get(tag)?.()
    this.loadCallbackMap.delete(tag)
  }
}