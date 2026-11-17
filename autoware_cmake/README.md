# autoware_cmake

This package provides CMake scripts for Autoware.

## Usage

### autoware_package.cmake

Call `autoware_package()` before defining build targets, which will set common options for Autoware.

```cmake
cmake_minimum_required(VERSION 3.5)
project(package_name)

find_package(autoware_cmake REQUIRED)
autoware_package()

ament_auto_add_library(...)
```

### autoware_ament_auto_package.cmake

Use `autoware_ament_auto_package()` as a replacement for `ament_auto_package()` to maintain Autoware's include structure across ROS 2 Humble, Jazzy, and Kilted.

This macro addresses a naming convention conflict between Autoware packages (which use `autoware_<module>` as package names) and Autoware include paths (which use `autoware/<module>/`). Starting with ROS 2 Kilted, `ament_auto_package()` will install headers to `include/${PROJECT_NAME}/`, which would create incorrect paths like `include/autoware_interpolation/autoware/interpolation/`.

#### Why use this?

- **Eliminates deprecation warnings** on ROS 2 Humble and Jazzy
- **Future-proof**: Works with ROS 2 Kilted+ without breaking changes
- **Maintains conventions**: Preserves `autoware/<module>/` include structure
- **Drop-in replacement**: Zero behavior change from `ament_auto_package()`

#### Example

```cmake
cmake_minimum_required(VERSION 3.14)
project(autoware_interpolation)

find_package(autoware_cmake REQUIRED)
autoware_package()

ament_auto_add_library(autoware_interpolation SHARED
  src/linear_interpolation.cpp
  src/spline_interpolation.cpp
)

if(BUILD_TESTING)
  # ... tests ...
endif()

# Use autoware_ament_auto_package() instead of ament_auto_package()
autoware_ament_auto_package()
```

#### Migration from ament_auto_package()

Simply replace `ament_auto_package()` with `autoware_ament_auto_package()` at the end of your `CMakeLists.txt`. All parameters supported by `ament_auto_package()` are also supported:

- `INSTALL_TO_PATH`: Install executables to `bin/` instead of `lib/${PROJECT_NAME}/`
- `INSTALL_TO_SHARE`: Install additional directories to `share/${PROJECT_NAME}/`

#### Export the libraries as CMake targets

Add `EXPORT_LIBRARY_TARGETS` to export each library of the package as a CMake target, `<package>::<library>`:

```cmake
autoware_ament_auto_package(EXPORT_LIBRARY_TARGETS)
```

A package that depends on it links the targets with `target_link_libraries(<target> ${<package>_TARGETS})`. `ament_auto_add_library()`, `ament_auto_add_executable()` and `ament_target_dependencies()` use the targets without a change. The package also keeps exporting `<package>_LIBRARIES` and `<package>_INCLUDE_DIRS`, so code that reads them keeps working.

The flag has the same name and behavior as in [ament/ament_cmake#455](https://github.com/ament/ament_cmake/pull/455), but it also keeps the classic export.

With the flag, CMake checks each exported library when it installs the export. Fix these cases in the package:

- An include folder inside the source or build folder stops the build. The macro fixes the `include` folder that `ament_auto_add_library()` adds. Wrap other folders in `$<BUILD_INTERFACE:...>`.
- A local target that an exported library links stops the build, for example the target of `generate_parameter_library()`. Add it to the export before the macro call: `list(APPEND ${PROJECT_NAME}_TARGETS <target>)`.
- An imported target of a dependency, for example `Eigen3::Eigen`, must be found in each package that uses the library, or that package stops with "the target was not found". The macro exports the dependencies of `package.xml` that are also run dependencies. If the CMake package name differs from the `package.xml` key, as for `eigen` and `Eigen3`, add `ament_export_dependencies(Eigen3)` before the macro call.
