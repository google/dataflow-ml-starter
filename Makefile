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

SILENT:
.PHONY:
.DEFAULT_GOAL := help

# Load environment variables from .env file
include .env
export

define PRINT_HELP_PYSCRIPT
import re, sys # isort:skip

matches = []
for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		matches.append(match.groups())

for target, help in sorted(matches):
    print("     %-25s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

PYTHON = python$(PYTHON_VERSION)

ifndef TF_MODEL_URI
	MODEL_ENV := "TORCH"
else
	MODEL_ENV := "TF"
endif

help: ## Print this help
	@echo
	@echo "  make targets:"
	@echo
	@$(PYTHON) -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

init-venv: ## Create virtual environment in venv folder
	@$(PYTHON) -m venv venv

init: init-venv ## Init virtual environment
	@./venv/bin/python3 -m pip install -U pip
	@$(shell sed "s|\$${BEAM_VERSION}|$(BEAM_VERSION)|g" requirements.prod.txt > requirements.txt)
	@./venv/bin/python3 -m pip install -r requirements.txt
	@./venv/bin/python3 -m pip install -r requirements.dev.txt
	@./venv/bin/python3 -m pre_commit install --install-hooks --overwrite
	@mkdir -p beam-output
	@echo "use 'source venv/bin/activate' to activate venv "

format: ## Run formatter on source code
	@./venv/bin/python3 -m black --config=pyproject.toml .

lint: ## Run linter on source code
	@./venv/bin/python3 -m black --config=pyproject.toml --check .
	@./venv/bin/python3 -m flake8 --config=.flake8 .

clean-lite: ## Remove pycache files, pytest files, etc
	@rm -rf build dist .cache .coverage .coverage.* *.egg-info
	@find . -name .coverage | xargs rm -rf
	@find . -name .pytest_cache | xargs rm -rf
	@find . -name .tox | xargs rm -rf
	@find . -name __pycache__ | xargs rm -rf
	@find . -name *.egg-info | xargs rm -rf

clean: clean-lite ## Remove virtual environment, downloaded models, etc
	@rm -rf venv
	@echo "run 'make init'"

test: lint ## Run tests
	@PYTHONPATH="./:./src" ./venv/bin/pytest -s -vv --cov-config=.coveragerc --cov-report html:htmlcov_v1 --cov-fail-under=50 tests/

run-direct: ## Run a local test with DirectRunner
ifeq ($(MODEL_ENV), "TORCH")
	time ./venv/bin/python3 -m src.run \
	--input data/openimage_10.txt \
	--output beam-output/beam_test_out.txt \
	--model_state_dict_path $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)
else
	time ./venv/bin/python3 -m src.run \
	--input data/openimage_10.txt \
	--output beam-output/beam_test_out.txt \
	--tf_model_uri $(TF_MODEL_URI)
endif

docker: ## Build a custom docker image and push it to Artifact Registry
	@$(shell sed "s|\$${BEAM_VERSION}|$(BEAM_VERSION)|g; s|\$${PYTHON_VERSION}|$(PYTHON_VERSION)|g" ${DOCKERFILE_TEMPLATE} > Dockerfile)
	docker build --platform linux/amd64 -t $(CUSTOM_CONTAINER_IMAGE) -f Dockerfile .
	docker push $(CUSTOM_CONTAINER_IMAGE)

run-df-gpu: ## Run a Dataflow job using the custom container with GPUs
	$(eval JOB_NAME := beam-ml-starter-gpu-$(shell date +%s)-$(shell echo $$$$))
ifeq ($(MODEL_ENV), "TORCH")
	time ./venv/bin/python3 -m src.run \
	--runner DataflowRunner \
	--job_name $(JOB_NAME) \
	--project $(PROJECT_ID) \
	--region $(REGION) \
	--machine_type $(MACHINE_TYPE) \
	--disk_size_gb $(DISK_SIZE_GB) \
	--staging_location $(STAGING_LOCATION) \
	--temp_location $(TEMP_LOCATION) \
	--setup_file ./setup.py \
	--device GPU \
	--dataflow_service_option $(SERVICE_OPTIONS) \
	--number_of_worker_harness_threads 1 \
	--experiments=disable_worker_container_image_prepull \
	--sdk_container_image $(CUSTOM_CONTAINER_IMAGE) \
	--sdk_location container \
	--input $(INPUT_DATA) \
	--output $(OUTPUT_DATA) \
	--model_state_dict_path  $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)
else
	time ./venv/bin/python3 -m src.run \
	--runner DataflowRunner \
	--job_name $(JOB_NAME) \
	--project $(PROJECT_ID) \
	--region $(REGION) \
	--machine_type $(MACHINE_TYPE) \
	--disk_size_gb $(DISK_SIZE_GB) \
	--staging_location $(STAGING_LOCATION) \
	--temp_location $(TEMP_LOCATION) \
	--setup_file ./setup.py \
	--device GPU \
	--dataflow_service_option $(SERVICE_OPTIONS) \
	--number_of_worker_harness_threads 1 \
	--experiments=disable_worker_container_image_prepull \
	--sdk_container_image $(CUSTOM_CONTAINER_IMAGE) \
	--sdk_location container \
	--input $(INPUT_DATA) \
	--output $(OUTPUT_DATA) \
	--tf_model_uri $(TF_MODEL_URI)
endif

run-df-cpu: ## Run a Dataflow job with CPUs and without Custom Container
	@$(shell sed "s|\$${BEAM_VERSION}|$(BEAM_VERSION)|g" requirements.txt > beam-output/requirements.txt)
	@$(eval JOB_NAME := beam-ml-starter-cpu-$(shell date +%s)-$(shell echo $$$$))
ifeq ($(MODEL_ENV), "TORCH")
	time ./venv/bin/python3 -m src.run \
	--runner DataflowRunner \
	--job_name $(JOB_NAME) \
	--project $(PROJECT_ID) \
	--region $(REGION) \
	--machine_type $(MACHINE_TYPE) \
	--disk_size_gb $(DISK_SIZE_GB) \
	--staging_location $(STAGING_LOCATION) \
	--temp_location $(TEMP_LOCATION) \
	--requirements_file requirements.txt \
	--setup_file ./setup.py \
	--input $(INPUT_DATA) \
	--output $(OUTPUT_DATA) \
	--model_state_dict_path  $(MODEL_STATE_DICT_PATH) \
	--model_name $(MODEL_NAME)
else
	time ./venv/bin/python3 -m src.run \
	--runner DataflowRunner \
	--job_name $(JOB_NAME) \
	--project $(PROJECT_ID) \
	--region $(REGION) \
	--machine_type $(MACHINE_TYPE) \
	--disk_size_gb $(DISK_SIZE_GB) \
	--staging_location $(STAGING_LOCATION) \
	--temp_location $(TEMP_LOCATION) \
	--requirements_file requirements.txt \
	--setup_file ./setup.py \
	--input $(INPUT_DATA) \
	--output $(OUTPUT_DATA) \
	--tf_model_uri $(TF_MODEL_URI)
endif

create-vm: ## Create a VM with GPU to test the docker image
	@./scripts/create-gpu-vm.sh

delete-vm: ## Delete a VM
	gcloud compute instances delete $(VM_NAME) --project $(PROJECT_ID) --zone $(ZONE) --quiet

check-beam: ## Check whether Beam is installed on GPU using VM with Custom Container
	@./scripts/check-beam.sh

check-tf-gpu: ## Check whether Tensorflow works on GPU using VM with Custom Container
	@./scripts/check-tf-on-gpu.sh

check-torch-gpu: ## Check whether PyTorch works on GPU using VM with Custom Container
	@./scripts/check-torch-on-gpu.sh

check-pipeline: ## Check whether the Beam pipeline can run on GPU using VM with Custom Container and DirectRunner
	@./scripts/check-pipeline.sh
