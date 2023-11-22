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
#include <napi/native_api.h>
#include "RNOH/ArkJS.h"
#include "RNOH/EventEmitRequestHandler.h"
#include "EventEmitters.h"

using namespace facebook;
namespace rnoh {

enum WebViewEventType {
    LOADING_ERROR = 0,
    LOADING_FINISH = 1,
    ON_MESSAGE = 2,
    SHOULD_START_LOAD_WITH_REQUEST = 3,
};

WebViewEventType getWebViewEventType(ArkJS &arkJs, napi_value eventObject) {
    auto eventType = arkJs.getString(arkJs.getObjectProperty(eventObject, "type"));
    if (eventType == "onLoadingError") {
        return WebViewEventType::LOADING_ERROR;
    } else if (eventType == "onLoadingFinish") {
        return WebViewEventType::LOADING_FINISH;
    } else if (eventType == "onMessage") {
        return WebViewEventType::ON_MESSAGE;
    } else if(eventType == "onShouldStartLoadWithRequest"){
        return WebViewEventType::SHOULD_START_LOAD_WITH_REQUEST;
    } else {
        throw std::runtime_error("Unknown Page event type");
    }
}

class WebViewEventEmitRequestHandler : public EventEmitRequestHandler {
    public:
        void handleEvent(EventEmitRequestHandler::Context const &ctx) override {
            if (ctx.eventName != "RNCWebView") {
                return;
            }
            ArkJS arkJs(ctx.env);
            auto eventEmitter = ctx.shadowViewRegistry->getEventEmitter<react::WebViewEventEmitter>(ctx.tag);
            if (eventEmitter == nullptr) {
                return;
            }

            switch (getWebViewEventType(arkJs,ctx.payload)){
              case WebViewEventType::LOADING_ERROR: {
                std::string url = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "url"));
                bool loading = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "loading"));
                std::string title = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "title"));
                bool canGoBack = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "canGoBack"));
                bool canGoForward = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "canGoForward"));
                double lockIdentifier = arkJs.getDouble(arkJs.getObjectProperty(ctx.payload, "lockIdentifier"));
                std::string domain = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "domain"));
                int code = (int)arkJs.getDouble(arkJs.getObjectProperty(ctx.payload, "code"));
                std::string description = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "description"));
                react::WebViewEventEmitter::OnLoadingError event{url, loading, title, canGoBack,
                    canGoForward, lockIdentifier, domain, code, description};
                eventEmitter->onLoadingError(event);
                break;
              }
              case WebViewEventType::LOADING_FINISH: {
                std::string url = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "url"));
                bool loading = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "loading"));
                std::string title = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "title"));
                bool canGoBack = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "canGoBack"));
                bool canGoForward = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "canGoForward"));
                double lockIdentifier = arkJs.getDouble(arkJs.getObjectProperty(ctx.payload, "lockIdentifier"));
                std::string navigationType = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "navigationType"));
                std::string mainDocumentURL = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "mainDocumentURL"));
                react::WebViewEventEmitter::OnLoadingFinish event{url, loading, title, canGoBack,
                    canGoForward, lockIdentifier, navigationType, mainDocumentURL};
                eventEmitter->onLoadingFinish(event);
                break;
              }
              case WebViewEventType::ON_MESSAGE: {
                std::string url = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "url"));
                bool loading = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "loading"));
                std::string title = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "title"));
                bool canGoBack = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "canGoBack"));
                bool canGoForward = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "canGoForward"));
                double lockIdentifier = arkJs.getDouble(arkJs.getObjectProperty(ctx.payload, "lockIdentifier"));
                std::string data = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "data"));
                react::WebViewEventEmitter::OnMessage event{url, loading, title, canGoBack,
                    canGoForward, lockIdentifier, data};
                eventEmitter->onMessage(event);
                break;
              }
              case WebViewEventType::SHOULD_START_LOAD_WITH_REQUEST:{
                std::string url = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "url"));
                bool loading = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "loading"));
                std::string title = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "title"));
                bool canGoBack = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "canGoBack"));
                bool canGoForward = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "canGoForward"));
                double lockIdentifier = arkJs.getDouble(arkJs.getObjectProperty(ctx.payload, "lockIdentifier"));
                std::string navigationType = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "navigationType"));
                std::string mainDocumentURL = arkJs.getString(arkJs.getObjectProperty(ctx.payload, "mainDocumentURL"));
                bool isTopFrame = arkJs.getBoolean(arkJs.getObjectProperty(ctx.payload, "isTopFrame"));
                react::WebViewEventEmitter::OnShouldStartLoadWithRequest event{url, loading, title, canGoBack,
                    canGoForward, lockIdentifier, navigationType,mainDocumentURL,isTopFrame};
                eventEmitter->onShouldStartLoadWithRequest(event);
                break;
              }
              default:
                break;
            }
        };
};
} // namespace rnoh