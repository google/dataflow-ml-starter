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

# third party libraries
import requests
from packaging.version import Version


def beam_versions(package_name, limit_releases=10):
    url = f"https://pypi.org/pypi/{package_name}/json"
    data = requests.get(url).json()
    versions = list(data["releases"].keys())
    versions.sort(key=Version, reverse=True)
    return versions[:limit_releases]


print("\n".join(beam_versions("apache-beam", 1)))
