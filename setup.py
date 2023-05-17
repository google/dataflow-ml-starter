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
import os

# third party libraries
import setuptools

required = []
if os.path.exists("requirements.txt"):
    with open("requirements.txt") as f:
        required = f.read().splitlines()

setuptools.setup(
    name="src",
    version="0.0.1",
    install_requires=required,
    packages=["src"],
)
