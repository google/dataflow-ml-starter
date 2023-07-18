#!/bin/bash

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

# Import environment variables from .env file.
source .env

# Check if the project ID and zone environment variables are set.
if [ -z "${PROJECT_ID}" ]; then
  echo "The PROJECT_ID environment variable is not set."
  exit 1
fi

if [ -z "${ZONE}" ]; then
  echo "The ZONE environment variable is not set."
  exit 1
fi

if [ -z "${VM_NAME}" ]; then
  echo "The VM_NAME environment variable is not set."
  exit 1
fi

if [ -z "${CUSTOM_CONTAINER_IMAGE}" ]; then
  echo "The CUSTOM_CONTAINER_IMAGE environment variable is not set."
  exit 1
fi

echo "Checking Tensorflow on GPU..."
gcloud compute ssh --strict-host-key-checking=no $VM_NAME --project $PROJECT_ID --zone=$ZONE --quiet --command \
"docker run --entrypoint /bin/bash --volume /var/lib/nvidia/lib64:/usr/local/nvidia/lib64 \
  --volume /var/lib/nvidia/bin:/usr/local/nvidia/bin \
  --privileged $CUSTOM_CONTAINER_IMAGE -c \
  \"python -c 'import tensorflow as tf; print(tf.config.list_physical_devices())'\""