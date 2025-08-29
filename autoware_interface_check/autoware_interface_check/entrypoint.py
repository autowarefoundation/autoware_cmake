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

import argparse
import textwrap
import time
import xml.dom.minidom as MD
import xml.etree.ElementTree as ET
import xml.sax.saxutils as sax

from .common.case import TestStatus
from .common.case import TestSuite
from . import param


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("target")
    parser.add_argument("--xunit-file")
    parser.add_argument("--xunit-name")
    args = parser.parse_args()

    start = time.time()

    suite = TestSuite.Load(args.target)
    for case in suite.cases:
        case.result = param.check(case.data)

    duration = time.time() - start

    for index, case in enumerate(suite.cases):
        print(f"Test #{index} ({case.result.status.name})")
        print("  message:", case.result.message)
        print("  details:")
        print(textwrap.indent(format_details(case.result.details), "    "))
        print()

    print("Summary")
    print("  all    :", suite.count())
    print("  success:", suite.count(TestStatus.Success))
    print("  failure:", suite.count(TestStatus.Failure))
    print("  errors :", suite.count(TestStatus.Error))

    if args.xunit_file:
        path = args.xunit_file
        name = args.xunit_name
        generate_xunit(path, suite, name, duration)


def generate_xunit(path, suite, name, duration):
    root = ET.Element("testsuite")
    root.set("name", name)
    root.set("tests", str(suite.count()))
    root.set("errors", str(suite.count(TestStatus.Error)))
    root.set("failures", str(suite.count(TestStatus.Failure)))
    root.set("time", f"{duration:.3f}")

    for index, case in enumerate(suite.cases):
        item = ET.SubElement(root, "testcase")
        item.set("name", f"Test #{index}")
        item.set("classname", name)

        if case.result.status == TestStatus.Failure:
            info = ET.SubElement(item, "failure")
            info.set("message", sax.quoteattr(case.result.message))
            info.text = sax.escape(format_details(case.result.details))

        if case.result.status == TestStatus.Error:
            info = ET.SubElement(item, "error")
            info.set("message", sax.quoteattr(case.result.message))
            info.text = sax.escape(format_details(case.result.details))

    with open(path, "w") as fp:
        xml = MD.parseString(ET.tostring(root, "UTF-8"))
        xml.writexml(fp, encoding="UTF-8", newl="\n", addindent="  ")


# Temporary
def format_details(details):
    return "\n".join(f"{key}: {value}" for key, value in details)
