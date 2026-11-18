cmake_minimum_required(VERSION 3.14)

project(autoware_cmake NONE)

find_package(ament_cmake_auto REQUIRED)
ament_auto_find_build_dependencies()

list(APPEND ${PROJECT_NAME}_CONFIG_EXTRAS
  "autoware_cmake-extras.cmake"
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()

  # cSpell:ignore DMACRO DSOURCE DWORK
  ament_add_test(test_export_library_targets
    GENERATE_RESULT_FOR_RETURN_CODE_ZERO
    COMMAND ${CMAKE_COMMAND}
      "-DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/test/export_library_targets"
      "-DWORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/test_export_library_targets"
      "-DMACRO_FILE=${CMAKE_CURRENT_SOURCE_DIR}/cmake/autoware_ament_auto_package.cmake"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/test/export_library_targets/run_test.cmake"
    TIMEOUT 300
  )
endif()

ament_auto_package(
  INSTALL_TO_SHARE
    cmake
)
