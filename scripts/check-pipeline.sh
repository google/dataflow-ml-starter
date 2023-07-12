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

vm_ssh="gcloud compute ssh --strict-host-key-checking=no $VM_NAME --project $PROJECT_ID --zone=$ZONE --quiet --command"
vm_scp="gcloud compute scp --strict-host-key-checking=no --project $PROJECT_ID --zone=$ZONE --quiet"

# Package the local code and copy it to VM
PACKAGE_NAME="src-0.0.1"
python3 setup.py sdist
$vm_ssh "sudo rm -fr ~/*"
$vm_scp dist/$PACKAGE_NAME.tar.gz data/openimage_10.txt $VM_NAME:~/
$vm_ssh "tar zxvf $PACKAGE_NAME.tar.gz; mv openimage_10.txt $PACKAGE_NAME"

# Test the model on GPUs
if [ -z "${TF_MODEL_URI}" ]; then
echo "Running the PyTorch model on GPU..."
$vm_ssh "docker run --entrypoint /bin/bash \
--volume /var/lib/nvidia/lib64:/usr/local/nvidia/lib64   --volume /var/lib/nvidia/bin:/usr/local/nvidia/bin \
--volume /home/\$USER/:/workspace/\$USER --privileged $CUSTOM_CONTAINER_IMAGE -c \
\"cd \$USER/$PACKAGE_NAME; python -m src.run --input openimage_10.txt  --output beam-output/beam_test_out.txt  --model_state_dict_path  $MODEL_STATE_DICT_PATH --model_name $MODEL_NAME --device GPU\""
else
echo "Running the Tensorflow model on GPU..."
$vm_ssh "docker run --entrypoint /bin/bash \
--volume /var/lib/nvidia/lib64:/usr/local/nvidia/lib64   --volume /var/lib/nvidia/bin:/usr/local/nvidia/bin \
--volume /home/\$USER/:/workspace/\$USER --privileged $CUSTOM_CONTAINER_IMAGE -c \
\"cd \$USER/$PACKAGE_NAME; python -m src.run --input openimage_10.txt  --output beam-output/beam_test_out.txt  --tf_model_uri $TF_MODEL_URI --device GPU\""
fi

$vm_ssh "[ -f './$PACKAGE_NAME/beam-output/beam_test_out.txt' ] && echo 'The DirectRunner run succeeded on GPU!' || echo 'The DirectRunner run failed on GPU!'"