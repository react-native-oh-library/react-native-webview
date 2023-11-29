/**
 * MIT License
 * 
 * Copyright (C) 2023 Huawei Device Co., Ltd.
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
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANT KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import { CustomReference } from './CutomReference';
import HashMap from '@ohos.util.HashMap';

export enum CallbackState {
  UNDECIDED,
  SHOULD_OVERRIDE,
  DO_NOT_OVERRIDE,
}

export class ShouldRequestUrl {
  private constructor() {
  }

  static nextLockIdentifier: number = 1;
  static ShouldRequestUrlLocks: HashMap<string, CustomReference> = new HashMap();
  static callBack: Function;

  static setCallBack(lockIdentifier: string, callBack: Function): void {
    let data: CustomReference = ShouldRequestUrl.ShouldRequestUrlLocks.get(lockIdentifier);
    data.setCallBack(callBack)
  }

  public static getNewData(): string {
    let lockIdentifier = ShouldRequestUrl.nextLockIdentifier++ + ''
    let custom = new CustomReference(CallbackState.UNDECIDED)
    ShouldRequestUrl.ShouldRequestUrlLocks.set(lockIdentifier, custom)
    return lockIdentifier
  }

  public static setValue(lockIdentifier: number, stateParam: CallbackState): void {
    let lock: string = lockIdentifier + '';
    if (ShouldRequestUrl.ShouldRequestUrlLocks.hasKey(lock)) {
      let data: CustomReference = ShouldRequestUrl.ShouldRequestUrlLocks.get(lock)
      data.setValue(stateParam)
    }
  }

  public static getValue(lockIdentifier: string): CallbackState {
    return ShouldRequestUrl.ShouldRequestUrlLocks.get(lockIdentifier).getValue()
  }
  public static removeData(lockIdentifier: string): void {
    ShouldRequestUrl.ShouldRequestUrlLocks.remove(lockIdentifier)
  }
}