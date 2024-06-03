/**
 * MIT License
 *
 * Copyright (C) 2024 Huawei Device Co., Ltd.
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

import type {
  DescriptorWrapperFactoryByDescriptorType,
  DescriptorWrapperFactoryByDescriptorTypeCtx
} from '@rnoh/react-native-openharmony/ts';
import { RNPackage, TurboModulesFactory, TurboModule, TurboModuleContext } from "@rnoh/react-native-openharmony/ts";
import { CallbackState, ShouldRequestUrl } from './ShouldRequestUrl';
import { RNC } from './namespace';

export class RNCWebViewTurboModule extends TurboModule {
  constructor(protected ctx: TurboModuleContext) {
    super(ctx);
  }

  getConstants() {
  }

  isFileUploadSupported(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      resolve()
    });
  }

  shouldStartLoadWithLockIdentifier(shouldStart: boolean, lockIdentifier: number) {
    ShouldRequestUrl.setValue(lockIdentifier, shouldStart ? CallbackState.DO_NOT_OVERRIDE : CallbackState.SHOULD_OVERRIDE)
  }
}

class WebViewTurboModulesFactory extends TurboModulesFactory{
  createTurboModule(name:string):TurboModule | null{
    if (name === RNC.RNCWebView.NAME) {
      return new RNCWebViewTurboModule(this.ctx);
    }
    return null;
  }

  hasTurboModule(name:string):boolean{
    return name === RNC.RNCWebView.NAME;

  }
}

export class RNCWebViewPackage extends RNPackage {
  createDescriptorWrapperFactoryByDescriptorType(ctx: DescriptorWrapperFactoryByDescriptorTypeCtx): DescriptorWrapperFactoryByDescriptorType {
    return {
      [RNC.RNCWebView.NAME]: (ctx) => new RNC.RNCWebView.DescriptorWrapper(ctx.descriptor)
    }
  }

  createTurboModulesFactory(ctx:TurboModuleContext):TurboModulesFactory{
    return new WebViewTurboModulesFactory(ctx);
  }
}