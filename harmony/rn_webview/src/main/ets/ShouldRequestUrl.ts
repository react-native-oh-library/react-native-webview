// Copyright (c) 2025 Huawei Device Co., Ltd. All rights reserved
// Use of this source code is governed by a Apache-2.0 license that can be
// found in the LICENSE file.

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