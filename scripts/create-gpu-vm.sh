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

if [ -z "${MACHINE_TYPE}" ]; then
  echo "The MACHINE_TYPE environment variable is not set."
  exit 1
fi

# Set the number of GPUs to attach to the VM.
GPU_COUNT=1
GPU_TYPE="nvidia-tesla-t4"

# Create the VM.
echo "Waiting for VM to be created (this will take a few minutes)..."

gcloud compute instances create $VM_NAME \
  --project $PROJECT_ID \
  --zone $ZONE \
  --machine-type $MACHINE_TYPE \
  --accelerator count=$GPU_COUNT,type=$GPU_TYPE \
  --image-family cos-stable \
  --image-project=cos-cloud  \
  --maintenance-policy TERMINATE \
  --restart-on-failure  \
  --boot-disk-size=200G \
  --scopes=cloud-platform

# Wait for the VM to be created.
STATUS=""
while [ "$STATUS" != "RUNNING" ]; do
    sleep 5
    STATUS=$(gcloud compute instances describe $VM_NAME --project $PROJECT_ID --zone=$ZONE --format="value(status)")
done

echo "VM $VM_NAME is now running."

# Print the VM's IP address.
echo "VM IP address: $(gcloud compute instances describe $VM_NAME --project $PROJECT_ID --zone=$ZONE --format='value(networkInterfaces[0].accessConfigs[0].natIP)')"

# Install GPU driver
echo "Installing Nvidia GPU driver..."
gcloud compute ssh --strict-host-key-checking=no $VM_NAME --project $PROJECT_ID --zone=$ZONE --tunnel-through-iap --quiet \
--command "cos-extensions install gpu && sudo mount --bind /var/lib/nvidia /var/lib/nvidia && sudo mount -o remount,exec /var/lib/nvidia"
echo "Getting the GPU driver information..."
gcloud compute ssh --strict-host-key-checking=no $VM_NAME --project $PROJECT_ID --zone=$ZONE --quiet --command "/var/lib/nvidia/bin/nvidia-smi"

# docker-credential-gcr
if [[ -n "$DOCKER_CREDENTIAL_REGISTRIES" ]]; then
    echo "HOME is defined."
    echo "Authenticating us-docker.pkg.dev..."
    gcloud compute ssh --strict-host-key-checking=no $VM_NAME --project $PROJECT_ID --zone=$ZONE --quiet \
    --command "docker-credential-gcr configure-docker --registries=$DOCKER_CREDENTIAL_REGISTRIES"
fi