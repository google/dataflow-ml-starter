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

FROM gcr.io/dataflow-templates-base/flex-template-launcher-image:latest as template_launcher

# Select an NVIDIA base image with desired GPU stack from https://ngc.nvidia.com/catalog/containers/nvidia:cuda
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

WORKDIR /workspace

COPY requirements.txt requirements.txt

RUN \
    # Add Deadsnakes repository that has a variety of Python packages for Ubuntu.
    # See: https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 \
    && echo "deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu focal main" >> /etc/apt/sources.list.d/custom.list \
    && echo "deb-src http://ppa.launchpad.net/deadsnakes/ppa/ubuntu focal main" >> /etc/apt/sources.list.d/custom.list \
    && apt-get update \
    && apt-get install -y curl \
        python3.8 \
        python3.8-venv \
        python3-venv \
        # With python3.8 package, distutils need to be installed separately.
        python3-distutils \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.8 10 \
    && curl https://bootstrap.pypa.io/pip/3.8/get-pip.py | python \
    && pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir tensorflow==2.12.1 \
    && pip install --no-cache-dir torch==2.0.0+cu118 torchvision==0.15.1+cu118 torchaudio==2.0.1 --index-url https://download.pytorch.org/whl/cu118

# Copy the run module
COPY my_project/ /workspace/my_project
RUN rm -fr /workspace/my_project/__pycache__

#Specifies which Python file to run to launch the Flex Template.
ENV FLEX_TEMPLATE_PYTHON_PY_FILE="my_project/run.py"

# Since we already downloaded all the dependencies, there's no need to rebuild everything.
ENV PIP_NO_DEPS=True

ENV PYTHONPATH "${PYTHONPATH}:/workspace/my_project/"

# Copy the Dataflow Template launcher
COPY --from=template_launcher /opt/google/dataflow/python_template_launcher /opt/google/dataflow/python_template_launcher

# Copy files from official SDK image, including script/dependencies.
# Note Python 3.8 is used since the above setup uses Python 3.8.
COPY --from=apache/beam_python3.8_sdk:${BEAM_VERSION} /opt/apache/beam /opt/apache/beam

# Set the entrypoint to the Dataflow Template launcher
# Use this if the launcher image is different with the custom container image
# ENTRYPOINT ["/opt/google/dataflow/python_template_launcher"]

# Set the entrypoint to Apache Beam SDK launcher.
ENTRYPOINT ["/opt/apache/beam/boot"]