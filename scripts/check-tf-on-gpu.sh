#!/bin/bash

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
gcloud compute ssh $VM_NAME --project $PROJECT_ID --zone=$ZONE --quiet --command \
"docker run --entrypoint /bin/bash --volume /var/lib/nvidia/lib64:/usr/local/nvidia/lib64 \
  --volume /var/lib/nvidia/bin:/usr/local/nvidia/bin \
  --privileged $CUSTOM_CONTAINER_IMAGE -c \
  \"python -c 'import tensorflow as tf; print(tf.config.list_physical_devices())'\""