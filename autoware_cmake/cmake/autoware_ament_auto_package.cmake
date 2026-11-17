# Copyright 2025 The Autoware Contributors
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

macro(autoware_ament_auto_package)
  # cSpell:ignore ARGN
  cmake_parse_arguments(_ARG_AUTOWARE_AMENT_AUTO_PACKAGE
    "INSTALL_TO_PATH;USE_SCOPED_HEADER_INSTALL_DIR;EXPORT_LIBRARY_TARGETS"
    ""
    "INSTALL_TO_SHARE"
    ${ARGN})

  # Export all found build dependencies which are also run dependencies
  set(_run_depends
    ${${PROJECT_NAME}_BUILD_EXPORT_DEPENDS}
    ${${PROJECT_NAME}_BUILDTOOL_EXPORT_DEPENDS}
    ${${PROJECT_NAME}_EXEC_DEPENDS})
  foreach(_dep
      ${${PROJECT_NAME}_FOUND_BUILD_DEPENDS}
      ${${PROJECT_NAME}_FOUND_BUILDTOOL_DEPENDS})
    if(_dep IN_LIST _run_depends)
      ament_export_dependencies("${_dep}")
    endif()
  endforeach()

  # Export and install include directory.
  # When USE_SCOPED_HEADER_INSTALL_DIR is enabled, headers are installed under
  # include/${PROJECT_NAME}. Otherwise, headers are installed under include.
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
    if(_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_USE_SCOPED_HEADER_INSTALL_DIR)
      ament_export_include_directories("include/${PROJECT_NAME}")
      install(DIRECTORY include/ DESTINATION include/${PROJECT_NAME}
      )
    else()
      ament_export_include_directories("include")
      install(DIRECTORY include/ DESTINATION include
      )
    endif()
  endif()

  # Export and install all libraries
  if(NOT ${PROJECT_NAME}_LIBRARIES STREQUAL "")
    # The classic export stays in both modes, so code that reads <pkg>_LIBRARIES keeps working.
    ament_export_libraries(${${PROJECT_NAME}_LIBRARIES})
    if(_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_EXPORT_LIBRARY_TARGETS)
      # A package can append more targets to ${PROJECT_NAME}_TARGETS before this call,
      # for example the target of generate_parameter_library(), as in ament/ament_cmake#455.
      list(APPEND ${PROJECT_NAME}_TARGETS ${${PROJECT_NAME}_LIBRARIES})
    else()
      install(
        TARGETS ${${PROJECT_NAME}_LIBRARIES}
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin
      )
    endif()
  endif()

  # Export the libraries as CMake targets
  if(_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_EXPORT_LIBRARY_TARGETS AND
      NOT "${${PROJECT_NAME}_TARGETS}" STREQUAL "")
    list(REMOVE_DUPLICATES ${PROJECT_NAME}_TARGETS)
    if(_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_USE_SCOPED_HEADER_INSTALL_DIR)
      set(_include_install_dir "include/${PROJECT_NAME}")
    else()
      set(_include_install_dir "include")
    endif()
    # ament_auto_add_library() adds the include folder as a plain source path. install(EXPORT)
    # rejects a source path, so it becomes a build path and an install path.
    foreach(_target ${${PROJECT_NAME}_TARGETS})
      get_target_property(_include_dirs ${_target} INTERFACE_INCLUDE_DIRECTORIES)
      if(_include_dirs)
        set(_new_include_dirs "")
        foreach(_dir IN LISTS _include_dirs)
          if(_dir STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}/include")
            list(APPEND _new_include_dirs
              "$<BUILD_INTERFACE:${_dir}>"
              "$<INSTALL_INTERFACE:${_include_install_dir}>")
          else()
            list(APPEND _new_include_dirs "${_dir}")
          endif()
        endforeach()
        set_target_properties(${_target} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_new_include_dirs}")
      endif()
    endforeach()
    install(
      TARGETS ${${PROJECT_NAME}_TARGETS}
      EXPORT ${PROJECT_NAME}Targets
      ARCHIVE DESTINATION lib
      LIBRARY DESTINATION lib
      RUNTIME DESTINATION bin
    )
    ament_export_targets(${PROJECT_NAME}Targets)
  endif()

  # Install executables
  if(NOT ${PROJECT_NAME}_EXECUTABLES STREQUAL "")
    if(_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_INSTALL_TO_PATH)
      set(_executable_destination "bin")
    else()
      set(_executable_destination "lib/${PROJECT_NAME}")
    endif()
    install(
      TARGETS ${${PROJECT_NAME}_EXECUTABLES}
      DESTINATION ${_executable_destination}
    )
  endif()

  # Install additional directories to share
  foreach(_dir ${_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_INSTALL_TO_SHARE})
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${_dir}")
      install(DIRECTORY "${_dir}/" DESTINATION "share/${PROJECT_NAME}/${_dir}")
    endif()
  endforeach()

  # Call ament_package with any unparsed arguments
  ament_package(${_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_UNPARSED_ARGUMENTS})
endmacro()
