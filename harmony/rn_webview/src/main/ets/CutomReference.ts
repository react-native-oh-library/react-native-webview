// Copyright (c) 2025 Huawei Device Co., Ltd. All rights reserved
// Use of this source code is governed by a Apache-2.0 license that can be
// found in the LICENSE file.

export class CustomReference {
  private atomicValue: number;
  private callBack!: Function;
  constructor(init: number) {
    this.atomicValue = init
  }

  getValue() {
    return this.atomicValue
  }

  setCallBack(callBack: Function) {
    this.callBack = callBack
  }

  getCallBack() {
    return this.callBack
  }

  setValue(newValue: number) {
    this.atomicValue = newValue
    if (this.callBack) {
      this.callBack()
    }
  }
}