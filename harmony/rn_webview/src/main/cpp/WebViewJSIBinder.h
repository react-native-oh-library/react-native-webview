/*
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
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#pragma once
#include "RNOHCorePackage/ComponentBinders/ViewComponentJSIBinder.h"

namespace rnoh {
    class WebViewJSIBinder : public ViewComponentJSIBinder {
    facebook::jsi::Object createNativeProps(facebook::jsi::Runtime &rt) override
    {
        auto object = ViewComponentJSIBinder::createNativeProps(rt);
        object.setProperty(rt, "newSource", "object");
        object.setProperty(rt, "javaScriptEnabled", "bool");
        object.setProperty(rt, "injectedJavaScript", "string");
        object.setProperty(rt, "messagingEnabled", "bool");
        object.setProperty(rt, "showsHorizontalScrollIndicator", "bool");
        object.setProperty(rt, "showsVerticalScrollIndicator", "bool");
        object.setProperty(rt, "textZoom", "int");
        object.setProperty(rt, "cacheEnabled", "bool");
        object.setProperty(rt, "cacheMode", "string");
        object.setProperty(rt, "domStorageEnabled", "bool");
        object.setProperty(rt, "scalesPageToFit", "bool");
        object.setProperty(rt, "messagingModuleName", "string");
        object.setProperty(rt, "shouldStartLoadWithRequestEnabled", "bool");
        object.setProperty(rt, "webviewDebuggingEnabled", "bool");
        object.setProperty(rt, "nestedScrollEnabled", "bool");
        return object;
    }

    facebook::jsi::Object createDirectEventTypes(facebook::jsi::Runtime &rt) override
    {
        facebook::jsi::Object events(rt);
        events.setProperty(rt, "topLoadingError", createDirectEvent(rt, "onLoadingError"));
        events.setProperty(rt, "topLoadingFinish", createDirectEvent(rt, "onLoadingFinish"));
        events.setProperty(rt, "topMessage", createDirectEvent(rt, "onMessage"));
        events.setProperty(rt, "topShouldStartLoadWithRequest", createDirectEvent(rt, "onShouldStartLoadWithRequest"));
        return events;
    }
    };
} // namespace rnoh