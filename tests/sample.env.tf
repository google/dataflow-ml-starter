################################################################################
### PYTHON SDK SETTINGS
################################################################################
PYTHON_VERSION=3.8
BEAM_VERSION=2.48.0
DOCKERFILE_TEMPLATE=tensorflow_gpu.Dockerfile
DOCKER_CREDENTIAL_REGISTRIES="us-docker.pkg.dev"
################################################################################
### GCP SETTINGS
################################################################################
PROJECT_ID=apache-beam-testing
REGION=us-central1
ZONE=us-central1-f
DISK_SIZE_GB=50
MACHINE_TYPE=n1-standard-2
VM_NAME=beam-ml-starter-gpu
################################################################################
### DATAFLOW JOB SETTINGS
################################################################################
STAGING_LOCATION=gs://temp-storage-for-perf-tests/loadtests
TEMP_LOCATION=gs://temp-storage-for-perf-tests/loadtests
CUSTOM_CONTAINER_IMAGE=us-docker.pkg.dev/apache-beam-testing/dataflow-ml-starter/tf_gpu:test
SERVICE_OPTIONS="worker_accelerator=type:nvidia-tesla-t4;count:1;install-nvidia-driver"
################################################################################
### DATAFLOW JOB MODEL SETTINGS
################################################################################
#TF_MODEL_URI: only support TF2 models (https://tfhub.dev/s?subtype=module,placeholder&tf-version=tf2)
TF_MODEL_URI=https://tfhub.dev/google/tf2-preview/mobilenet_v2/classification/4
################################################################################
### DATAFLOW JOB INPUT&OUTPUT SETTINGS
################################################################################
INPUT_DATA="gs://apache-beam-ml/testing/inputs/openimage_50k_benchmark.txt"
OUTPUT_DATA="gs://temp-storage-for-end-to-end-tests/temp-storage-for-end-to-end-tests/dataflow-ml-starter/result_gpu.txt"