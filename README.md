# Dataflow ML Starter Project

## Summary
This repo contains a simple Beam RunInference project, which demonstrates how to run this Beam pipeline using DirectRunner to develop and test
and launch the production job using DataflowRunner on either CPUs or GPUs. It can be served as a boilerplate to create a new Dataflow ML project.

**This is not an officially supported Google product**.

## Prerequisites

* conda
* git
* make
* docker
* gcloud
* python3-venv

```bash
sudo apt-get update
sudo apt-get install -y python3-venv git make time wget
```
Install Docker on Debian: https://docs.docker.com/engine/install/debian/
Without sudo,
```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

## Directory structure
```
.
├── LICENSE
├── .env.template           <- A configuration template file to define environment-specific variables
├── Makefile                <- Makefile with commands and type `make` to get the command list
├── README.md               <- The top-level README for developers using this project
├── data                    <- Any data for local development and testing
│   └── openimage_10.txt    <- A sample test data that contains the gcs file path for each image
├── pyproject.toml          <- The TOML format Python project configuration file
├── requirements.dev.txt    <- Packages for the development such as `pytest`
├── requirements.prod.txt   <- Packages for the production environment and produces `requirements.txt`
├── scripts                 <- utility bash scripts
├── setup.py                <- Used in `python setup.py sdist` to create the multi-file python package
├── my_project              <- Source code for use in this project, also your python package module name
│   ├── __init__.py         <- Makes my_project a Python module
│   ├── config.py           <- `pydantic` model classes to define sources, sinks, and models
│   ├── pipeline.py         <- Builds the Beam RunInference pipeline
│   └── run.py              <- A run module to parse the command options and run the Beam pipeline
├── tensor_rt.Dockerfile    <- A Dockerfile to create a customer container with TensorRT
└── tests                   <- Tests to cover local developments
    └── test_pipeline.py
```

## User Guide

**This process is only tested on GCE VMs with Debian.**

### Step 1: Clone this repo and edit .env

```bash
git clone https://github.com/google/dataflow-ml-starter.git
cd df-ml-starter
cp .env.template .env
```
Use your editor to fill in the information in the `.env` file.

If you want to try other pytorch models under `gs://apache-beam-ml/models/`,
```bash
gsutil ls gs://apache-beam-ml/models/
```
you need to edit `config.py` to add more model names.

It is highly recommended to run through this guide once using `mobilenet_v2` for image classification.

All the useful actions can be triggered using `make`:
```console
$ make

make targets:

     check-beam                Check whether Beam is installed on GPU using VM with Custom Container
     check-pipeline            Check whether the Beam pipeline can run on GPU using VM with Custom Container and DirectRunner
     check-tf-gpu              Check whether Tensorflow works on GPU using VM with Custom Container
     check-torch-gpu           Check whether PyTorch works on GPU using VM with Custom Container
     clean                     Remove virtual environment, downloaded models, etc
     clean-lite                Remove pycache files, pytest files, etc
     create-flex-template      Create a Flex Template file using a Flex Template custom container
     create-vm                 Create a VM with GPU to test the docker image
     delete-vm                 Delete a VM
     docker                    Build a custom docker image and push it to Artifact Registry
     format                    Run formatter on source code
     help                      Print this help
     init                      Init virtual environment
     init-venv                 Create virtual environment in venv folder
     lint                      Run linter on source code
     run-df-cpu                Run a Dataflow job with CPUs and without Custom Container
     run-df-gpu                Run a Dataflow job using the custom container with GPUs
     run-df-gpu-flex           Run a Dataflow job using the Flex Template
     run-direct                Run a local test with DirectRunner
     test                      Run tests
     test-latest-env           Replace the Beam vesion with the latest version (including release candidates)
```

### Pipeline Details

This project contains a simple RunInference Beam pipeline,
```
Read the GCS file that contains image GCS paths (beam.io.ReadFromText) ->
Pre-process the input image, run a Pytorch or Tensorflow image classification model, post-process the results -->
Write all predictions back to the GCS output file
```
The input image data is created from the ImageNet images.

The entire code flows in this way:

* `.env` defines the environment variables such as Torch or TF models, model name, Dockerfile template, etc.
* `Makefile` reads these environment variables from `.env` and based on the make targets, it can run tests, build docker images, run Dataflow jobs with CPUs or GPUs.
* `run.py` is called by the`Makefile` targets to parse the input arguments and set `ModelConfig`, `SourceConfig`, and `SinkConfig` defined in `config.py`, then calls `build_pipeline` from `pipeline.py` to build the final Beam pipeline


To customize the pipeline, modify `build_pipeline` in [pipeline.py](https://github.com/google/dataflow-ml-starter/blob/main/my_project/pipeline.py). It defines how to read the image data from TextIO, pre-process the images, score them, post-process the predictions,
and at last save the results using TextIO.

[config.py](https://github.com/google/dataflow-ml-starter/blob/main/my_project/config.py) contains a set of `pydantic` models to specify the configurations for sources, sinks, and models and validate them. Users can easily add more Pytorch classification models. [Here](https://github.com/apache/beam/tree/master/sdks/python/apache_beam/examples/inference) contains more examples.

### `.env` Details

Most of options are configured by the `.env` file.
Below is one example to use the Pytorch `mobilenet_v2` model for image classification:
```
################################################################################
### PYTHON SDK SETTINGS
################################################################################
PYTHON_VERSION=3.10
BEAM_VERSION=2.48.0
DOCKERFILE_TEMPLATE=pytorch_gpu.Dockerfile
DOCKER_CREDENTIAL_REGISTRIES="us-docker.pkg.dev"
################################################################################
### GCP SETTINGS
################################################################################
PROJECT_ID=apache-beam-testing
REGION=us-central1
DISK_SIZE_GB=50
MACHINE_TYPE=n1-standard-2
VM_NAME=beam-ml-starter-gpu-1
################################################################################
### DATAFLOW JOB SETTINGS
################################################################################
STAGING_LOCATION=gs://temp-storage-for-perf-tests/loadtests
TEMP_LOCATION=gs://temp-storage-for-perf-tests/loadtests
CUSTOM_CONTAINER_IMAGE=us-docker.pkg.dev/apache-beam-testing/xqhu/pytorch_gpu:latest
SERVICE_OPTIONS="worker_accelerator=type:nvidia-tesla-t4;count:1;install-nvidia-driver"
################################################################################
### DATAFLOW JOB MODEL SETTINGS
################################################################################
MODEL_STATE_DICT_PATH="gs://apache-beam-ml/models/torchvision.models.mobilenet_v2.pth"
MODEL_NAME=mobilenet_v2
################################################################################
### DATAFLOW JOB INPUT&OUTPUT SETTINGS
################################################################################
INPUT_DATA="gs://apache-beam-ml/testing/inputs/openimage_50k_benchmark.txt"
OUTPUT_DATA="gs://temp-storage-for-end-to-end-tests/torch/result_gpu_xqhu.txt"
```
Most of options are intuitive. `DOCKERFILE_TEMPLATE` provides the Dockerfile template that will be used to build the custom container. `CUSTOM_CONTAINER_IMAGE` is the Docker image storage location.
In default, we use GPUs (i.e., T4) with the custom container defined by `SERVICE_OPTIONS` for this Dataflow job. `MODEL_STATE_DICT_PATH` and `MODEL_NAME` defines the Pytorch model information. For this Beam pipeline, we use the GCS buckets for input and output data.

### Custom container
We provide three Dockerfile templates as examples to show how to build a custom container:
|Name|Description|
|---|---|
|tensor_rt.Dockerfile| TensorRT + Python 3.8|
|pytorch_gpu.Dockerfile| Pytorch with GPUs + Python 3.10|
|tensorflow_gpu.Dockerfile | Tensorflow with GPUs + Python 3.8|

Note You should keep your local Python environment same as the one defined in Dockerfile.
These Dockerfile examples should be customized based on your project requirements.

### Step 2: Initialize a venv for your project
```bash
make init
source venv/bin/activate
```
Note you must make sure the base Python version matches the version defined in `.env`.
The base python can be configured using [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html), e.g.,
```bash
conda create --name py38 python=3.8
conda activate py38
```
If anything goes wrong, you can rebuild the `venv`,
```bash
make clean
make init
```
To check the `venv` is created correctly,
```bash
make test
```

### Step 3: Test the Beam pipeline using DirectRunner
`DirectRunner` provides the local way to validate whether your Beam pipeline works correctly,
```bash
make run-direct
```

### Step 4: Run the Beam pipeline using DataflowRunner
To run a Dataflow job using CPUs without a custom container, try this:
```bash
make run-df-cpu
```
When using resnet101 to score 50k images, the job took ~30m and cost ~1.4$ with resnet101.
For `mobilenet_v2`, it cost 0.5$ with ~22m.
Note the cost and time depends on your job settings and the regions.

#### Build Custom Container with GPU supports
Running Dataflow GPU jobs needs to build a custom container,
```bash
make docker
```
The final docker image will be pushed to Artifact Registry. For this guide,
we use `tensor_rt.Dockerfile` to demonstrate how to build the container to run the inference on GPUs with TensorRT.
**Note given the base image issue for TensorRT, only Python 3.8 should be used when running GPUs.**
You can follow [this doc](https://cloud.google.com/dataflow/docs/gpu/use-gpus#custom-container) to create other GPU containers.

#### Test Custom Container using GCE VM
It is highly recommended to test your custom container locally before running it with Dataflow,
```bash
make create-vm
```
This creates a GCE VM with a T4 GPU and installs nvidia driver. It will take a few minutes.
Now using this VM allows you to test whether the docker container is built correctly,
```bash
# check whether Beam is installed in Custom Container
make check-beam
# check whether Tensorflow can use GPUs in Custom Container
make check-tf-gpu
# check whether PyTorch can use GPUs in Custom Container
make check-torch-gpu
# check whether DirectRunner can run on GPUs in Custom Container
make check-pipeline
```
Note these commands will take some time to download your container.
You should see outputs similar to these:
```bash
Checking Python version on VM...
Python 3.8.10
Checking venv exists on VM...
python3-venv/now 3.8.2-0ubuntu2 amd64 [installed,local]
Checking Beam Version on VM...
2.48.0
Checking Tensorflow on GPU...
[PhysicalDevice(name='/physical_device:CPU:0', device_type='CPU'), PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
Checking PyTorch on GPU...
True
Tesla T4
...
The DirectRunner run succeeded on GPU!
```
The last line will display whether the pipeline can run successfully on VM GPUs in Custom Container.

After finishing tests, you can remove this VM,
```bash
make delete-vm
```

#### Run the Beam pipeline using DataflowRunner on GPUs
This runs a Dataflow job with GPUs,
```bash
make run-df-gpu
```
When using resnet101 to score 50k images, the job took ~1h and cost ~0.5$ with resnet101.
For `mobilenet_v2`, it cost 0.05$ with ~1h.
Note the cost and time depends on your job settings and the regions.

### Run the Beam pipeline with the Pub/Sub source
When `INPUT_DATA` from the `.env` file defines a valid Pub/Sub topic (e.g., `projects/apache-beam-testing/topics/Imagenet_openimage_50k_benchmark`),
the Beam pipeline is created using the Pub/Sub source with `FixedWindows` and switches to `beam.io.fileio.WriteToFiles` that supports the streaming pipeline.
Note for this toy example, writing the predictions to a GCS bucket is not efficient since the file size is quite small with few bytes.
In practice, you might tune up [the autoscaling options](https://cloud.google.com/dataflow/docs/guides/troubleshoot-autoscaling) to optimize the streaming pipeline performance.
Note that the streaming job will run forever until it is canceled or drained.

### Run the Beam pipeline with Dataflow Flex Templates
If you prefer to package all your code into a custom container and allow users to easily access your Beam pipeline,
Dataflow Flex Template could be handy to create and run a Flex Template job using Google Cloud CLI or Google Cloud console.
More importantly, building the flex templates container from the custom SDK container image can produce a reproducible launch environment that is [compatible with the runtime environment](https://beam.apache.org/documentation/sdks/python-pipeline-dependencies/#make-the-launch-environment-compatible-with-the-runtime-environment).
(More benefits about templates are [here](https://cloud.google.com/dataflow/docs/concepts/dataflow-templates#benefits).)

Since the custom container is already created, it is straightforward to adapt Dataflow Flex Templates:
1. create a [`metadata.json`](https://github.com/google/dataflow-ml-starter/blob/main/flex/metadata.json) file that contains the parameters required by your Beam pipeline. In this example, we can add `input`, `output`, `device`, `model_name`, `model_state_dict_path`, and `tf_model_uri` as the parameters that can be passed in by users. [Here](https://cloud.google.com/dataflow/docs/guides/templates/using-flex-templates#example-metadata-file) is another example metadata file.
2. convert the custom container to your template container following [this](https://cloud.google.com/dataflow/docs/guides/templates/configuring-flex-templates#use_custom_container_images). [`tensorflow_gpu.flex.Dockerfile`](https://github.com/google/dataflow-ml-starter/blob/main/tensorflow_gpu.flex.Dockerfile) is one example converted from `tensorflow_gpu.Dockerfile`. Only two parts are needed: switch to the Dataflow Template launcher entrypoint and package `my_project` into this container. Change `CUSTOM_CONTAINER_IMAGE` in `.env` and run `make docker` to create the custom container for Flex Templates.
3. `make create-flex-template` creates a template spec file in a Cloud Storage bucket defined by the env `TEMPLATE_FILE_GCS_PATH` that contains all of the necessary information to run the job, such as the SDK information and metadata. This calls the CLI `gcloud dataflow flex-template build`.
4. `make run-df-gpu-flex` runs a Flex Template pipeline using the spec file from `TEMPLATE_FILE_GCS_PATH`. This calls the CLI `gcloud dataflow flex-template run`.

More information about Flex Templates can be found [here](https://cloud.google.com/dataflow/docs/guides/templates/using-flex-templates).


## FAQ

### Permission error when using any GCP command
```bash
gcloud auth login
gcloud auth application-default login
# replace it with the appropriate region
gcloud auth configure-docker us-docker.pkg.dev
# or if you use docker-credential-gcr
docker-credential-gcr configure-docker --registries=us-docker.pkg.dev
```
Make sure you specify the appropriate region for Artifact Registry.

### AttributeError: Can't get attribute 'default_tensor_inference_fn'
```
AttributeError: Can't get attribute 'default_tensor_inference_fn' on <module 'apache_beam.ml.inference.pytorch_inference' from '/usr/local/lib/python3.8/dist-packages/apache_beam/ml/inference/pytorch_inference.py'>
```
This error indicates your Dataflow job uses the old Beam SDK. If you use `--sdk_location container`, it means your Docker container has the old Beam SDK.

### QUOTA_EXCEEDED
```
Startup of the worker pool in zone us-central1-a failed to bring up any of the desired 1 workers. Please refer to https://cloud.google.com/dataflow/docs/guides/common-errors#worker-pool-failure for help troubleshooting. QUOTA_EXCEEDED: Instance 'benchmark-tests-pytorch-i-05041052-ufe3-harness-ww4n' creation failed: Quota 'NVIDIA_T4_GPUS' exceeded. Limit: 32.0 in region us-central1.
```
Please check https://cloud.google.com/compute/docs/regions-zones and select another zone with your desired machine type to relaunch the Dataflow job.

### ERROR: failed to solve: failed to fetch anonymous token: unexpected status: 401 Unauthorized
```
failed to solve with frontend dockerfile.v0: failed to create LLB definition: failed to authorize: rpc error: code = Unknown desc = failed to fetch anonymous token: unexpected status: 401 Unauthorized
```
Restarting the docker could resolve this issue.

### Check the built container
```bash
docker run --rm -it --entrypoint=/bin/bash $CUSTOM_CONTAINER_IMAGE
```

### Errors could happen when the custom container is not built correctly

Check Cloud Logs, pay attention to INFO for Worker logs:
```
INFO 2023-05-06T15:13:01.237562007Z The virtual environment was not created successfully because ensurepip is not
INFO 2023-05-06T15:13:01.237601258Z available. On Debian/Ubuntu systems, you need to install the python3-venv
INFO 2023-05-06T15:13:01.237607714Z package using the following command.
```
or (might be caused by building the container on Mac OS)
```
exec /opt/apache/beam/boot: no such file or directory
```

## Useful Links
* https://cloud.google.com/dataflow/docs/guides/using-custom-containers#docker
* https://cloud.google.com/dataflow/docs/gpu/use-gpus#custom-container
* https://beam.apache.org/documentation/sdks/python-pipeline-dependencies/
* https://github.com/apache/beam/blob/master/.test-infra/jenkins/job_InferenceBenchmarkTests_Python.groovy
* https://cloud.google.com/dataflow/docs/gpu/troubleshoot-gpus#debug-vm
* https://github.com/GoogleCloudPlatform/python-docs-samples/tree/main/dataflow/flex-templates/streaming_beam
* https://cloud.google.com/dataflow/docs/guides/templates/using-flex-templates
* https://cloud.google.com/dataflow/docs/guides/templates/configuring-flex-templates#use_custom_container_images