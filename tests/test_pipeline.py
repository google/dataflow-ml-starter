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

# standard libraries
from pathlib import Path

# third party libraries
import apache_beam as beam

# Dataflow ML libraries
# dfml libraries
from src.config import ModelConfig, SinkConfig, SourceConfig
from src.pipeline import build_pipeline

DATA_FILE_PATH = Path(__file__).parent.parent / "data"


def test_build_pipeline():
    model_config = ModelConfig(
        model_state_dict_path="gs://apache-beam-ml/models/torchvision.models.resnet101.pth",
        model_class_name="resnet101",
        model_params={"num_classes": 1000},
    )
    source_config = SourceConfig(input=str(DATA_FILE_PATH / "openimage_10.txt"))
    sink_config = SinkConfig(output="beam-output/my_output.txt")

    p = beam.Pipeline()
    build_pipeline(p, source_config=source_config, sink_config=sink_config, model_config=model_config)


def test_build_pipeline_with_tf():
    model_config = ModelConfig(
        tf_model_uri="https://tfhub.dev/google/imagenet/mobilenet_v1_075_192/quantops/classification/3",
    )
    source_config = SourceConfig(input=str(DATA_FILE_PATH / "openimage_10.txt"))
    sink_config = SinkConfig(output="beam-output/my_output.txt")

    p = beam.Pipeline()
    build_pipeline(p, source_config=source_config, sink_config=sink_config, model_config=model_config)


def test_source_config_streaming():
    source_config = SourceConfig(input=str(DATA_FILE_PATH / "openimage_10.txt"))
    assert source_config.streaming is False
    source_config = SourceConfig(input="projects/apache-beam-testing/topics/Imagenet_openimage_50k_benchmark")
    assert source_config.streaming is True
