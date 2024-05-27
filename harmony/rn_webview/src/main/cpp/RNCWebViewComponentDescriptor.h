
#pragma once

// This file was generated.

#include <react/renderer/core/ConcreteComponentDescriptor.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/components/view/ViewShadowNode.h>

namespace facebook {
namespace react {

extern const char RNCWebViewComponentName[] = "RNCWebView";

class RNCWebViewProps : public ViewProps {
  public:
    RNCWebViewProps() = default;

    RNCWebViewProps(const PropsParserContext &context, const RNCWebViewProps &sourceProps, const RawProps &rawProps)
        : ViewProps(context, sourceProps, rawProps) {}
};

using RNCWebViewShadowNode = ConcreteViewShadowNode<
    RNCWebViewComponentName,
    RNCWebViewProps,
    ViewEventEmitter>;

class RNCWebViewComponentDescriptor final
    : public ConcreteComponentDescriptor<RNCWebViewShadowNode> {
  public:
    RNCWebViewComponentDescriptor(ComponentDescriptorParameters const &parameters)
        : ConcreteComponentDescriptor(parameters) {}
};

} // namespace react
} // namespace facebook
