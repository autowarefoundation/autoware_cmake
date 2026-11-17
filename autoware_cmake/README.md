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

The wrapper also takes `USE_SCOPED_HEADER_INSTALL_DIR`. With it, the headers go to `include/${PROJECT_NAME}/` instead of `include/`.

#### Export the libraries as CMake targets

Add `EXPORT_LIBRARY_TARGETS` to export each library of the package as a CMake target, `<package>::<library>`:

```cmake
autoware_ament_auto_package(EXPORT_LIBRARY_TARGETS)
```

A package that depends on it can link the targets with `target_link_libraries(<target> ${<package>_TARGETS})`. On all distributions, `ament_auto_add_library()` and `ament_auto_add_executable()` use the targets without a change. On Humble and Jazzy, `ament_target_dependencies()` uses them too. The headers of the package reach these packages as system headers. For `ament_auto_add_library()` and `ament_auto_add_executable()`, this is as before. An `ament_target_dependencies()` call without `SYSTEM` gave them as normal headers before.

The package also keeps exporting its own `<package>_LIBRARIES` and `<package>_INCLUDE_DIRS`. But the classic variables one level downstream change. When package B depends on package A, and A uses the flag, `B_LIBRARIES` still holds the library file of A, and it also holds the targets of the dependencies of A. `B_INCLUDE_DIRS` and `B_RECURSIVE_DEPENDENCIES` no longer hold the entries of the dependencies of A.

The flag takes its name from the open upstream proposal [ament/ament_cmake#455](https://github.com/ament/ament_cmake/pull/455). It differs from that proposal in these points:

- It keeps the classic export.
- It exports the targets in `${PROJECT_NAME}_TARGETS` only with the flag.
- The installed include folder follows `USE_SCOPED_HEADER_INSTALL_DIR`.
- It marks the installed include folder as a system folder for the packages that use the library.
- It stops when an exported library links a dependency that is only a build dependency.

##### Problems that the flag shows

With the flag, CMake checks each exported library when it configures the package, before anything compiles. Fix these cases in the package:

- An include folder inside the source or build folder stops the configure step. The macro handles the `include` folder that `ament_auto_add_library()` adds. Wrap other folders in `$<BUILD_INTERFACE:...>`. If the package installs such a folder, also add `$<INSTALL_INTERFACE:...>` with the install path.
- A local target that an exported library links stops the configure step, for example the target of `generate_parameter_library()`. Add it to the export before the macro call: `list(APPEND ${PROJECT_NAME}_TARGETS <target>)`.
- A dependency of an exported library must reach each package that uses the library, or that package stops with "the target was not found". The macro passes on a dependency only when `package.xml` lists it as `<depend>`, `<build_export_depend>` or `<exec_depend>`. If the dependency is only a `<build_depend>`, the macro stops and asks you to change it to `<depend>`. If the CMake package name differs from the `package.xml` key, as for `eigen` and `Eigen3`, add `ament_export_dependencies(Eigen3)` before the macro call.

Two more effects do not stop the build:

- The `PUBLIC` compile options and definitions of an exported library now reach every package that links it. Make them `PRIVATE` when only the library needs them.
- With `colcon build --symlink-install`, the exported libraries are copied to the install folder, not linked. After a rebuild outside colcon, run `colcon build` again to update the install folder.
