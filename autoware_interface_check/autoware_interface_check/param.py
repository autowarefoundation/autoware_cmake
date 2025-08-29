# Copyright 2025 The Autoware Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json

import jsonschema
import yaml

from .common.case import TestResult
from .common.path import FilePath


def validate(schema_path, params_path):
    details = (
        ("schema", str(schema_path)),
        ("params", str(params_path)),
    )
    with schema_path.path.open() as fp:
        schema = json.load(fp)
    with params_path.path.open() as fp:
        target = yaml.safe_load(fp)
    try:
        jsonschema.validate(target, schema)
        return TestResult.Success("OK", details)
    except jsonschema.ValidationError as error:
        return TestResult.Failure(error.message, details)


def check(data: dict):
    try:
        schema = FilePath.Parse(data["schema"])
        params = FilePath.Parse(data["params"])
        return validate(schema, params)
    except Exception as error:
        return TestResult.Error(repr(error), "")
