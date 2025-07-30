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

import { TM } from './generated/ts';
import { AnyThreadTurboModule } from '@rnoh/react-native-openharmony/ts';
import Logger from './Logger';

const TAG = "WebViewTurboModule"

export class WebViewTurboModule extends AnyThreadTurboModule implements TM.RNCWebViewModule.Spec {
  private shouldStartParamsMap : Map<number,ShouldStartParams> = new Map();

  isFileUploadSupported(): Promise<boolean> {
    return Promise.resolve(true)
  }

  shouldStartLoadWithLockIdentifier(shouldStart: boolean, lockIdentifier: number): void {
    Logger.debug("shouldStartLoadWithLockIdentifier:" + shouldStart + " lockIdentifier:" + lockIdentifier)
    let shouldStartParams = this.shouldStartParamsMap.get(lockIdentifier)
    Logger.debug("shouldStartLoadWithLockIdentifier setShouldStartParams:" + JSON.stringify(shouldStartParams))
    if (shouldStartParams) {
      shouldStartParams.shouldStart = shouldStart
      shouldStartParams.lockState = shouldStart ? ShouldOverrideCallbackState.ALLOW_LOADING : ShouldOverrideCallbackState.SHOULD_OVERRIDE;
    }
    this.shouldStartParamsMap.set(lockIdentifier,shouldStartParams || new ShouldStartParams())
  }


  setShouldStartParams(params: ShouldStartParams){
    Logger.debug("setShouldStartParams:" + JSON.stringify(params))
    this.shouldStartParamsMap.set(params.lockIdentifier,params)
  }
}

// 锁状态
export enum ShouldOverrideCallbackState {
  /**
   * 初始状态
   */
  UNDECIDED,
  /**
   * 阻止加载
   */
  SHOULD_OVERRIDE,
  /**
   * 允许加载
   */
  ALLOW_LOADING,
}

@Sendable
export class ShouldStartParams {
  shouldStart: boolean = true
  lockIdentifier: number = -1
  // 对应ShouldOverrideCallbackState
  lockState: number = 0
}