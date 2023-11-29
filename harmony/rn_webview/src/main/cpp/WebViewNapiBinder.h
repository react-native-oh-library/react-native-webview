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

#pragma once
#include "RNOHCorePackage/ComponentBinders/ViewComponentNapiBinder.h"
#include "Props.h"

namespace rnoh {

  class WebViewNapiBinder : public ViewComponentNapiBinder {
    public:
      napi_value createProps(napi_env env, facebook::react::ShadowView const shadowView) override
      {
        napi_value napiViewProps = ViewComponentNapiBinder::createProps(env, shadowView);
        if (auto props = std::dynamic_pointer_cast<const facebook::react::WebViewProps>(shadowView.props)) {
          auto objectBuilder = ArkJS(env).getObjectBuilder(napiViewProps);
          auto sourceObject = ArkJS(env).createObjectBuilder();
          sourceObject.addProperty("uri", props->newSource.uri);
          sourceObject.addProperty("method", props->newSource.method);
          sourceObject.addProperty("body", props->newSource.body);
          sourceObject.addProperty("html", props->newSource.html);
          sourceObject.addProperty("baseUrl", props->newSource.baseUrl);
          sourceObject.addProperty("headers", props->newSource.headers);
          return objectBuilder.addProperty("newSource", sourceObject.build())
              .addProperty("javaScriptEnabled", props->javaScriptEnabled)
              .addProperty("injectedJavaScript", props->injectedJavaScript)
              .addProperty("messagingEnabled", props->messagingEnabled)
              .addProperty("showsHorizontalScrollIndicator", props->showsHorizontalScrollIndicator)
              .addProperty("showsVerticalScrollIndicator", props->showsVerticalScrollIndicator)
              .addProperty("textZoom", props->textZoom)
              .addProperty("cacheEnabled", props->cacheEnabled)
              .addProperty("cacheMode", static_cast<int>(props->cacheMode))
              .addProperty("domStorageEnabled", props->domStorageEnabled)
              .addProperty("scalesPageToFit", props->scalesPageToFit)
              .addProperty("messagingModuleName", props->messagingModuleName)
              .addProperty("shouldStartLoadWithRequestEnabled", props->shouldStartLoadWithRequestEnabled)
              .addProperty("webviewDebuggingEnabled", props->webviewDebuggingEnabled)
              .build();
        }
        return napiViewProps;
      };
  };
  
} // namespace rnoh