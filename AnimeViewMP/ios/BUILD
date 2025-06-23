# Copyright 2019 The MediaPipe Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application", "ios_framework")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "//mediapipe/examples/ios:bundle_id.bzl",
    "BUNDLE_ID_PREFIX",
    "example_provisioning",
)

licenses(["notice"])  # Apache 2.0

MIN_IOS_VERSION = "17.6"

IOS_FAMILIES = [
    "iphone",
    "ipad",
]

FRAMEWORK_HEADERS = [
    "ObjcppLib.h",
]

# Make sure the framework gets embedded into the app:
# In General > Frameworks, Libraries, and Embedded Content set FacialSearch.framework to "Embed & Sign".
# Connect your device and run.
ios_framework(
    name = "AnimeViewMP",
    hdrs = FRAMEWORK_HEADERS,
    bundle_id = BUNDLE_ID_PREFIX + ".AnimeViewMPFramework",
    bundle_name = "AnimeViewMP",
    families = IOS_FAMILIES,
    infoplists = [
        "//mediapipe/examples/ios/common:Info.plist",
        "Info.plist",
    ],
    minimum_os_version = MIN_IOS_VERSION,
    visibility = ["//visibility:public"],
    deps = [
        ":ObjcppLib",
        "@ios_opencv//:OpencvFramework",
    ],
)

objc_library(
    name = "ObjcppLib",
    srcs = [
        "ObjcppLib.mm",
    ],
    hdrs = FRAMEWORK_HEADERS,
    copts = ["-std=c++17"],  # https://github.com/google/mediapipe/issues/2275#issuecomment-877145926
    data = [
        "//mediapipe/examples/AnimeViewMP/graphs:AnimeViewGPU.binarypb",
        "//mediapipe/models:whitebox_cartoon_gan_640x360_fp16.tflite",
        
        # "//mediapipe/models:whitebox_cartoon_gan_540x960_fp16.tflite",
        # "//mediapipe/models:whitebox_cartoon_gan_960x540_fp16.tflite",
        # "//mediapipe/models:whitebox_cartoon_gan_360x640_fp16.tflite",
        # "//mediapipe/models:whitebox_cartoon_gan_640x360_fp16_1.tflite",
    ],
    deps = [
        "//mediapipe/objc:mediapipe_framework_ios",
        "//mediapipe/objc:mediapipe_input_sources_ios",
        "//mediapipe/objc:mediapipe_layer_renderer",
    ] + select({
        "//mediapipe:ios_i386": [],
        "//mediapipe:ios_x86_64": [],
        "//conditions:default": [
            "//mediapipe/examples/AnimeViewMP/graphs:gpu_calculators",
        ],
    }),
)
