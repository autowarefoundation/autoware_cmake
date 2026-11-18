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
project(export_test_producer_scoped CXX)

find_package(ament_cmake_auto REQUIRED)
ament_auto_find_build_dependencies()
include("${AUTOWARE_AMENT_AUTO_PACKAGE_FILE}")

ament_auto_add_library(${PROJECT_NAME} SHARED src/producer_scoped.cpp)

add_library(${PROJECT_NAME}_helper INTERFACE)
target_compile_definitions(${PROJECT_NAME}_helper INTERFACE EXPORT_TEST_HELPER_VALUE=3)
target_link_libraries(${PROJECT_NAME} ${PROJECT_NAME}_helper)
list(APPEND ${PROJECT_NAME}_TARGETS ${PROJECT_NAME}_helper)

autoware_ament_auto_package(EXPORT_LIBRARY_TARGETS USE_SCOPED_HEADER_INSTALL_DIR)
