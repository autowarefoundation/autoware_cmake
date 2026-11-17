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

# Test of autoware_ament_auto_package(EXPORT_LIBRARY_TARGETS). It builds and installs two
# producer packages with the flag, then builds a consumer that links them and runs it.
# A third producer must stop at configure time.
#
# Usage: cmake -DSOURCE_DIR=<this folder> -DWORK_DIR=<empty folder>
#   -DMACRO_FILE=<autoware_ament_auto_package.cmake> -P run_test.cmake

# cSpell:ignore ARGN DAUTOWARE DCMAKE
function(run_step name)
  execute_process(COMMAND ${ARGN}
    RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE output)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "${name} failed with ${result}:\n${output}")
  endif()
endfunction()

# The packages keep their manifest as package.xml.in, so that colcon and rosdep do not find
# them as packages of the workspace.
function(copy_package name)
  file(COPY "${SOURCE_DIR}/${name}" DESTINATION "${WORK_DIR}/src")
  file(RENAME "${WORK_DIR}/src/${name}/package.xml.in" "${WORK_DIR}/src/${name}/package.xml")
endfunction()

function(configure_package name)
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S "${WORK_DIR}/src/${name}"
      -B "${WORK_DIR}/build/${name}"
      "-DCMAKE_INSTALL_PREFIX=${WORK_DIR}/install"
      "-DCMAKE_PREFIX_PATH=${WORK_DIR}/install"
      "-DAUTOWARE_AMENT_AUTO_PACKAGE_FILE=${MACRO_FILE}"
    RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE output)
  set(configure_result ${result} PARENT_SCOPE)
  set(configure_output "${output}" PARENT_SCOPE)
endfunction()

file(REMOVE_RECURSE "${WORK_DIR}")
foreach(name export_test_producer export_test_producer_scoped export_test_consumer export_test_build_depend_only)
  copy_package(${name})
endforeach()

foreach(name export_test_producer export_test_producer_scoped export_test_consumer)
  configure_package(${name})
  if(NOT configure_result EQUAL 0)
    message(FATAL_ERROR "configure ${name} failed with ${configure_result}:\n${configure_output}")
  endif()
  run_step("build ${name}" ${CMAKE_COMMAND} --build "${WORK_DIR}/build/${name}")
  run_step("install ${name}" ${CMAKE_COMMAND} --install "${WORK_DIR}/build/${name}")
endforeach()

# Both executables return 0 only when every library and the helper definition arrived.
run_step("export_test_consumer_auto" "${WORK_DIR}/build/export_test_consumer/export_test_consumer_auto")
run_step("export_test_consumer_targets" "${WORK_DIR}/build/export_test_consumer/export_test_consumer_targets")

configure_package(export_test_build_depend_only)
if(configure_result EQUAL 0)
  message(FATAL_ERROR "configure export_test_build_depend_only must fail, but it passed")
endif()
# CMake wraps long messages over several lines.
string(REGEX REPLACE "[ \t\r\n]+" " " configure_output_one_line "${configure_output}")
if(NOT configure_output_one_line MATCHES "lists 'rcutils' only as a build dependency")
  message(FATAL_ERROR "configure export_test_build_depend_only failed for another reason:\n${configure_output}")
endif()

message(STATUS "All checks passed")
