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
#include "RNOH/Package.h"
#include "RNOH/ArkTSTurboModule.h"
#include "./RNCWebViewJSIBinder.h"
#include "./RNCWebViewComponentDescriptor.h"
#include "./RNCWebViewTurboModule.h"


using namespace rnoh;
using namespace facebook;


class WebViewTurboModuleFactoryDelegate : public TurboModuleFactoryDelegate {
public:
    SharedTurboModule createTurboModule(Context ctx, const std::string &name) const override {
                if (name == "RNCWebView") {
                    return std::make_shared<RNCWebViewTurboModule>(ctx, name);
                }
        return nullptr;
    };
};
namespace rnoh {


class WebViewEventEmitRequestHandler : public EventEmitRequestHandler {
public:
    void handleEvent(Context const &ctx) override {
        auto eventEmitter = ctx.shadowViewRegistry->getEventEmitter<facebook::react::EventEmitter>(ctx.tag);
        if (eventEmitter == nullptr) {
            return;
        }

        std::vector<std::string> supportedEventNames = {
            "contentSizeChange",
            "renderProcessGone",
            "contentProcessDidTerminate",
            "customMenuSelection",
            "fileDownload",
            "loadingError",
            "loadingFinish",
            "loadingProgress",
            "loadingStart",
            "httpError",
            "message",
            "openWindow",
            "scroll",
            "shouldStartLoadWithRequest",
        };
        if (std::find(supportedEventNames.begin(), supportedEventNames.end(), ctx.eventName) !=
            supportedEventNames.end()) {
            eventEmitter->dispatchEvent(ctx.eventName, ArkJS(ctx.env).getDynamic(ctx.payload));
        }
    }
};

class WebViewPackage : public Package {
public:
    WebViewPackage(Package::Context ctx) : Package(ctx) {}

    std::unique_ptr<TurboModuleFactoryDelegate> createTurboModuleFactoryDelegate() override {
        return std::make_unique<WebViewTurboModuleFactoryDelegate>();
    }

    std::vector<facebook::react::ComponentDescriptorProvider> createComponentDescriptorProviders() override {
        return {
            facebook::react::concreteComponentDescriptorProvider<facebook::react::RNCWebViewComponentDescriptor>(),
        };
    }

    ComponentJSIBinderByString createComponentJSIBinderByName() override {
        return {{"RNCWebView", std::make_shared<RNCWebViewJSIBinder>()}};
    };

    ComponentNapiBinderByString createComponentNapiBinderByName() override { return {}; };

    EventEmitRequestHandlers createEventEmitRequestHandlers() override {
        return {
            std::make_shared<WebViewEventEmitRequestHandler>(),
        };
    }
};
} // namespace rnoh