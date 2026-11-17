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
  if(_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_USE_SCOPED_HEADER_INSTALL_DIR)
    set(_include_install_dir "include/${PROJECT_NAME}")
  else()
    set(_include_install_dir "include")
  endif()
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
    ament_export_include_directories("${_include_install_dir}")
    install(DIRECTORY include/ DESTINATION ${_include_install_dir})
  endif()

  # Export and install all libraries
  if(NOT ${PROJECT_NAME}_LIBRARIES STREQUAL "")
    # An INTERFACE library has no file, so the classic export skips it, as ament_auto_package()
    # does on Jazzy and later. Otherwise a consumer stops with "exports the library ... which
    # couldn't be found". The target export below handles INTERFACE libraries.
    set(_libraries_with_files "")
    foreach(_library ${${PROJECT_NAME}_LIBRARIES})
      get_target_property(_library_type ${_library} TYPE)
      if(NOT "${_library_type}" STREQUAL "INTERFACE_LIBRARY")
        list(APPEND _libraries_with_files ${_library})
      endif()
    endforeach()
    # The classic export stays in both modes until every package uses EXPORT_LIBRARY_TARGETS
    # (phase 4 of autowarefoundation/autoware#7412).
    if(NOT "${_libraries_with_files}" STREQUAL "")
      ament_export_libraries(${_libraries_with_files})
    endif()
    if(_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_EXPORT_LIBRARY_TARGETS)
      # A package can append more targets to ${PROJECT_NAME}_TARGETS before this call,
      # for example the target of generate_parameter_library().
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
  if(_ARG_AUTOWARE_AMENT_AUTO_PACKAGE_EXPORT_LIBRARY_TARGETS)
    if("${${PROJECT_NAME}_TARGETS}" STREQUAL "")
      message(WARNING "autoware_ament_auto_package(EXPORT_LIBRARY_TARGETS): "
        "${PROJECT_NAME} has no library to export.")
    else()
      list(REMOVE_DUPLICATES ${PROJECT_NAME}_TARGETS)

      # ament_auto_add_library() links the targets of every found build dependency, but only
      # run dependencies are passed on. A consumer would stop with "the target was not found".
      if(NOT "${${PROJECT_NAME}_LIBRARIES}" STREQUAL "")
        foreach(_dep ${${PROJECT_NAME}_FOUND_BUILD_DEPENDS})
          if(NOT _dep IN_LIST _run_depends AND NOT "${${_dep}_TARGETS}" STREQUAL "")
            message(FATAL_ERROR "autoware_ament_auto_package(EXPORT_LIBRARY_TARGETS): "
              "the libraries of ${PROJECT_NAME} link the targets of '${_dep}', but package.xml "
              "lists '${_dep}' only as a build dependency. Change it to <depend>.")
          endif()
        endforeach()
      endif()

      foreach(_target ${${PROJECT_NAME}_TARGETS})
        # The installed include folder comes first, so that consumers do not get an older copy
        # of these headers from a folder that a dependency exports, for example /opt/ros.
        # The compiler searches every normal include folder before every system include folder,
        # so this order does not help a consumer that sets CMAKE_NO_SYSTEM_FROM_IMPORTED, where
        # the folders of the dependencies are normal include folders.
        # ament_auto_add_library() adds the include folder as a plain source path, which
        # install(EXPORT) rejects, so that path stays for the build only. Other source or build
        # paths stop install(EXPORT) on purpose.
        set(_new_include_dirs "")
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
          list(APPEND _new_include_dirs "$<INSTALL_INTERFACE:${_include_install_dir}>")
        endif()
        get_target_property(_include_dirs ${_target} INTERFACE_INCLUDE_DIRECTORIES)
        if(_include_dirs)
          foreach(_dir IN LISTS _include_dirs)
            string(REGEX REPLACE "/+$" "" _dir_without_slash "${_dir}")
            if(_dir_without_slash STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}/include")
              list(APPEND _new_include_dirs "$<BUILD_INTERFACE:${_dir_without_slash}>")
            else()
              list(APPEND _new_include_dirs "${_dir}")
            endif()
          endforeach()
        endif()
        if(NOT "${_new_include_dirs}" STREQUAL "")
          set_target_properties(${_target} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_new_include_dirs}")
        endif()
        # Consumers get the headers as system headers, as ament_target_dependencies(SYSTEM) gave
        # them before. CMake does this for imported targets only by default, and
        # mrt_cmake_modules turns that default off with CMAKE_NO_SYSTEM_FROM_IMPORTED.
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
          set_property(TARGET ${_target} APPEND PROPERTY INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
            "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${_include_install_dir}>")
        endif()
      endforeach()

      install(
        TARGETS ${${PROJECT_NAME}_TARGETS}
        EXPORT ${PROJECT_NAME}Targets
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin
      )
      ament_export_targets(${PROJECT_NAME}Targets HAS_LIBRARY_TARGET)
    endif()
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
