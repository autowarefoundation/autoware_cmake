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

from enum import Enum
from pathlib import Path

import yaml


class TestStatus(Enum):
    Null = 0
    Success = 1
    Failure = 2
    Error = 3
    Skipped = 4


class TestResult:
    def __init__(self, status, message, details):
        self.status = status
        self.message = message
        self.details = details

    @staticmethod
    def Success(message="", details=""):
        return TestResult(TestStatus.Success, message, details)

    @staticmethod
    def Failure(message="", details=""):
        return TestResult(TestStatus.Failure, message, details)

    @staticmethod
    def Error(message="", details=""):
        return TestResult(TestStatus.Error, message, details)


class TestCase:
    def __init__(self, data):
        self.data = data
        self.result = TestResult(TestStatus.Null, "", "")


class TestSuite:
    def __init__(self, cases):
        self.cases = cases

    def count(self, status=None):
        if status is None:
            return len(self.cases)
        else:
            return sum(1 for case in self.cases if case.result.status == status)

    @staticmethod
    def Load(path: Path | str):
        path = Path(path) if type(path) is str else path
        with path.open() as fp:
            suite = yaml.safe_load(fp)
        return TestSuite([TestCase(data) for data in suite.get("param-checks", [])])
