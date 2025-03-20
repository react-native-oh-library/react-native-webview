// Copyright (c) 2025 Huawei Device Co., Ltd. All rights reserved
// Use of this source code is governed by a Apache-2.0 license that can be
// found in the LICENSE file.

export type UnsafeMixed<T> = T;

// Fabric doesn't support optional props, so we need to use UnsafeMixed
// https://github.com/rnmapbox/maps/pull/3082#discussion_r1339858750
export type OptionalProp<T> = UnsafeMixed<T>;