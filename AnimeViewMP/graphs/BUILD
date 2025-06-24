# Copyright 2020 The MediaPipe Authors.
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

load("@rules_cc//cc:defs.bzl", "cc_library")
load("//mediapipe/framework/tool:mediapipe_graph.bzl", "mediapipe_binary_graph", "mediapipe_simple_subgraph")

licenses(["notice"])  # Apache 2.0

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "cpu_calculators",
    deps = [
        "//mediapipe/calculators/core:flow_limiter_calculator",
        "//mediapipe/calculators/tensor:image_to_tensor_calculator",
        "//mediapipe/calculators/tensor:tensor_converter_calculator",
        "//mediapipe/calculators/tensor:inference_calculator",
        "//mediapipe/calculators/util:from_image_calculator",

        "//mediapipe/examples/AnimeViewMP/calculators:tensor_to_image_calculator",
    ],
)

cc_library(
    name = "gpu_calculators",
    deps = [
        "//mediapipe/calculators/core:flow_limiter_calculator",
        "//mediapipe/calculators/tensor:image_to_tensor_calculator",
        "//mediapipe/calculators/tensor:tensor_converter_calculator",
        "//mediapipe/calculators/tensor:inference_calculator",
        "//mediapipe/calculators/util:from_image_calculator",
        "//mediapipe/calculators/image:color_convert_calculator",
        
        "//mediapipe/examples/AnimeViewMP/calculators:tensor_to_image_calculator",
    ],
)

mediapipe_binary_graph(
    name = "anime_view_gpu_binary_graph",
    graph = "AnimeViewGPU.pbtxt",
    output_name = "AnimeViewGPU.binarypb",
    deps = [":gpu_calculators"],
)
