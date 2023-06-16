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

ARG TF_SERVING_BUILD_IMAGE=nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

FROM ${TF_SERVING_BUILD_IMAGE}

WORKDIR /workspace

COPY requirements.txt requirements.txt

RUN apt-get update \
    && apt install python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python3-venv python3-pip -y

RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && rm -f requirements.txt

# Copy files from official SDK image, including script/dependencies.
COPY --from=apache/beam_python${PYTHON_VERSION}_sdk:${BEAM_VERSION} /opt/apache/beam /opt/apache/beam

# Set the entrypoint to Apache Beam SDK launcher.
ENTRYPOINT ["/opt/apache/beam/boot"]