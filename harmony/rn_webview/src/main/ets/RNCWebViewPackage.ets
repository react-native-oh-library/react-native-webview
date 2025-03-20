// Copyright (c) 2025 Huawei Device Co., Ltd. All rights reserved
// Use of this source code is governed by a Apache-2.0 license that can be
// found in the LICENSE file.

import type {
  DescriptorWrapperFactoryByDescriptorType,
  DescriptorWrapperFactoryByDescriptorTypeCtx,
} from '@rnoh/react-native-openharmony/ts';
import { RNC, TM } from './generated/ts';
import { AnyThreadTurboModuleFactory, AnyThreadTurboModule } from '@rnoh/react-native-openharmony/ts';
import { RNOHPackage } from '@rnoh/react-native-openharmony';
import { WebViewTurboModule } from './WebViewTurboModule'
import { WorkerTurboModuleContext } from '@rnoh/react-native-openharmony/src/main/ets/RNOH/RNOHContext';

export class RNCWebViewPackage extends RNOHPackage  {
  createDescriptorWrapperFactoryByDescriptorType(ctx: DescriptorWrapperFactoryByDescriptorTypeCtx): DescriptorWrapperFactoryByDescriptorType {
    return {
      "RNCWebView": (ctx) => new RNC.RNCWebView.DescriptorWrapper(ctx.descriptor)
    }
  }

  createAnyThreadTurboModuleFactory(ctx: WorkerTurboModuleContext): AnyThreadTurboModuleFactory {
    return new WebViewTurboModulesFactory(ctx);
  }
}

class WebViewTurboModulesFactory extends AnyThreadTurboModuleFactory {
  createTurboModule(name: string): AnyThreadTurboModule | null {
    if (name === TM.RNCWebViewModule.NAME) {
      return new WebViewTurboModule(this.ctx);
    }
    return null;
  }

  hasTurboModule(name: string): boolean {
    return name === TM.RNCWebViewModule.NAME;
  }
}