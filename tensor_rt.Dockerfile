#  Copyright 2023 Google LLC

#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at

#       https://www.apache.org/licenses/LICENSE-2.0

#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# This needs Python 3.8 for your local runtime environment
ARG PYTORCH_SERVING_BUILD_IMAGE=nvcr.io/nvidia/pytorch:22.11-py3

FROM ${PYTORCH_SERVING_BUILD_IMAGE}

ENV PATH="/usr/src/tensorrt/bin:${PATH}"

WORKDIR /workspace

COPY requirements.txt requirements.txt

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt install python3.8 python3.8-venv python3-venv -y \
    && pip install --upgrade pip \
    && apt-get install ffmpeg libsm6 libxext6 -y --no-install-recommends \
    && pip install cuda-python onnx numpy onnxruntime common \
    && pip install git+https://github.com/facebookresearch/detectron2.git@5aeb252b194b93dc2879b4ac34bc51a31b5aee13 \
    && pip install git+https://github.com/NVIDIA/TensorRT#subdirectory=tools/onnx-graphsurgeon

RUN pip install --no-cache-dir -r requirements.txt && rm -f requirements.txt

# Copy files from official SDK image, including script/dependencies.
COPY --from=apache/beam_python3.8_sdk:${BEAM_VERSION} /opt/apache/beam /opt/apache/beam

# Set the entrypoint to Apache Beam SDK launcher.
ENTRYPOINT ["/opt/apache/beam/boot"]