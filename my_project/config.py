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
import re
from enum import Enum

# third party libraries
from pydantic import BaseModel, Field, root_validator, validator


class ModelName(str, Enum):
    RESNET101 = "resnet101"
    MOBILENET_V2 = "mobilenet_v2"


class ModelConfig(BaseModel):
    model_state_dict_path: str = Field(None, description="path that contains the torch model state directory")
    model_class_name: ModelName = Field(None, description="Reference to the class definition of the model.")
    model_params: dict = Field(
        None,
        description="Parameters passed to the constructor of the model_class. "
        "These will be used to instantiate the model object in the RunInference API.",
    )
    tf_model_uri: str = Field(None, description="TF model uri from https://tfhub.dev/")
    device: str = Field("CPU", description="Device to be used on the Runner. Choices are (CPU, GPU)")
    min_batch_size: int = 10
    max_batch_size: int = 100

    @root_validator
    def validate_fields(cls, values):
        v = values.get("model_state_dict_path")
        if v and values.get("tf_model_uri"):
            raise ValueError("Cannot specify both model_state_dict_path and tf_model_uri")
        if v is None and values.get("tf_model_uri") is None:
            raise ValueError("At least one of model_state_dict_path or tf_model_uri must be specified")
        if v and values.get("model_class_name") is None:
            raise ValueError("model_class_name must be specified when using model_state_dict_path")
        if v and values.get("model_params") is None:
            raise ValueError("model_params must be specified when using model_state_dict_path")
        return values


def _validate_topic_path(topic_path):
    pattern = r"projects/.+/topics/.+"
    return bool(re.match(pattern, topic_path))


class SourceConfig(BaseModel):
    input: str = Field(..., description="the input path to a text file or a Pub/Sub topic")
    images_dir: str = Field(
        None,
        description="Path to the directory where images are stored."
        "Not required if image names in the input file have absolute path.",
    )
    streaming: bool = False

    @validator("streaming", pre=True, always=True)
    def set_streaming(cls, v, values):
        return _validate_topic_path(values["input"])


class SinkConfig(BaseModel):
    output: str = Field(..., description="the output path to save results as a text file")
