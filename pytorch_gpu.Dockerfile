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

# This uses Ubuntu with Python 3.10
ARG PYTORCH_SERVING_BUILD_IMAGE=pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime

FROM ${PYTORCH_SERVING_BUILD_IMAGE}

# Check that the chosen base image provides the expected version of Python interpreter.
ARG PY_VERSION=3.10
RUN [[ $PY_VERSION == `python -c 'import sys; print("%s.%s" % sys.version_info[0:2])'` ]] \
   || { echo "Could not find Python interpreter or Python version is different from ${PY_VERSION}"; exit 1; }

WORKDIR /workspace

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt \
    && rm -f requirements.txt \
    # Verify that there are no conflicting dependencies.
    && pip check

# Copy files from official SDK image, including script/dependencies.
COPY --from=apache/beam_python${PYTHON_VERSION}_sdk:${BEAM_VERSION} /opt/apache/beam /opt/apache/beam

# Set the entrypoint to Apache Beam SDK launcher.
ENTRYPOINT ["/opt/apache/beam/boot"]