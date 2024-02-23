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

"""A run module that runs a Beam pipeline to perform image classification."""

# standard libraries
import argparse
import logging

# third party libraries
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, SetupOptions
from apache_beam.runners.runner import PipelineResult

# Dataflow ML libraries
from my_project.config import ModelConfig, SinkConfig, SourceConfig
from my_project.pipeline import build_pipeline


def parse_known_args(argv):
    """Parses args for the workflow."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", dest="input", required=True, help="Path to the text file containing image names.")
    parser.add_argument(
        "--output", dest="output", required=True, help="Path where to save output predictions." " text file."
    )
    parser.add_argument(
        "--model_state_dict_path", dest="model_state_dict_path", required=False, help="Path to the model's state_dict."
    )
    parser.add_argument("--model_name", dest="model_name", required=False, help="model name, e.g. resnet101")
    parser.add_argument(
        "--tf_model_uri", dest="tf_model_uri", required=False, help="tfhub model URI from https://tfhub.dev/"
    )
    parser.add_argument(
        "--images_dir",
        default=None,
        help="Path to the directory where images are stored."
        "Not required if image names in the input file have absolute path.",
    )
    parser.add_argument(
        "--device",
        default="CPU",
        help="Device to be used on the Runner. Choices are (CPU, GPU).",
    )
    return parser.parse_known_args(argv)


def run(argv=None, save_main_session=True, test_pipeline=None) -> PipelineResult:
    """
    Args:
      argv: Command line arguments defined for this example.
      save_main_session: Used for internal testing.
      test_pipeline: Used for internal testing.
    """
    known_args, pipeline_args = parse_known_args(argv)

    # setup configs
    model_config = ModelConfig(
        model_state_dict_path=known_args.model_state_dict_path,
        model_class_name=known_args.model_name,
        model_params={"num_classes": 1000},
        tf_model_uri=known_args.tf_model_uri,
        device=known_args.device,
    )

    source_config = SourceConfig(input=known_args.input)
    sink_config = SinkConfig(output=known_args.output)

    # setup pipeline
    pipeline_options = PipelineOptions(pipeline_args, streaming=source_config.streaming)
    pipeline_options.view_as(SetupOptions).save_main_session = save_main_session

    pipeline = test_pipeline
    if not test_pipeline:
        pipeline = beam.Pipeline(options=pipeline_options)

    # build the pipeline using configs
    build_pipeline(pipeline, source_config=source_config, sink_config=sink_config, model_config=model_config)

    # run it
    result = pipeline.run()
    result.wait_until_finish()
    return result


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()
