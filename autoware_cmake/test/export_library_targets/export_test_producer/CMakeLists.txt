# Copyright 2026 The Autoware Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.14)
project(export_test_producer CXX)

find_package(ament_cmake_auto REQUIRED)
ament_auto_find_build_dependencies()
include("${AUTOWARE_AMENT_AUTO_PACKAGE_FILE}")

ament_auto_add_library(${PROJECT_NAME} SHARED src/producer.cpp)
# The same folder as above, with a trailing slash, as some packages add it
target_include_directories(${PROJECT_NAME} PUBLIC include/)

# An INTERFACE library in the library list, which has no file to export. The test adds it by
# hand, because ament_auto_add_library() on Humble has no INTERFACE option.
add_library(${PROJECT_NAME}_definitions INTERFACE)
target_compile_definitions(${PROJECT_NAME}_definitions INTERFACE EXPORT_TEST_DEFINITIONS_VALUE=5)
list(APPEND ${PROJECT_NAME}_LIBRARIES ${PROJECT_NAME}_definitions)

autoware_ament_auto_package(EXPORT_LIBRARY_TARGETS)
