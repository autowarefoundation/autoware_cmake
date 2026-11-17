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
project(export_test_consumer CXX)

find_package(ament_cmake_auto REQUIRED)
ament_auto_find_build_dependencies()
include("${AUTOWARE_AMENT_AUTO_PACKAGE_FILE}")

# mrt_cmake_modules sets this, so imported targets do not give system headers by default.
set(CMAKE_NO_SYSTEM_FROM_IMPORTED ON)
add_compile_options(-Wall -Wextra -Werror)

# Links the producers through ament_auto, with no explicit call
ament_auto_add_executable(export_test_consumer_auto src/main.cpp)

# Links the producers through their exported targets
add_executable(export_test_consumer_targets src/main.cpp)
target_link_libraries(export_test_consumer_targets
  ${export_test_producer_TARGETS}
  ${export_test_producer_scoped_TARGETS}
)

autoware_ament_auto_package()
