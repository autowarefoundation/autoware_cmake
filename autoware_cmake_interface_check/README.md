# autoware_cmake_interface_check

This package provides colcon test integration for [autoware_interface_check](../autoware_interface_check/README.md).

## Usage

Add the following to package.xml.

```xml
<test_depend>autoware_cmake_interface_check</test_depend>
```

Add the following to CMakeLists.txt.

```cmake
if(BUILD_TESTING)
  find_package(autoware_cmake_interface_check REQUIRED)
  autoware_interface_check("test/autoware_interface_check.yaml")
endif()
```
