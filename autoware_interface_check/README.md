# autoware_interface_check

This package provides tools to checking Autoware interfaces.

- param-check

## Usage

The following steps are required to run the test:

1. Create a test definition file such as [example/interface.yaml](./example/interface.yaml).
2. Run the check command using the above test definition file.

## Command

```bash
autoware-interface-check test-definition-file
```

| Argument             | Type   | Description                                              |
| -------------------- | ------ | -------------------------------------------------------- |
| test-definition-file | string | Path of test definition file.                            |
| --xunit-file         | string | File path of xUnit. This is for colcon test integration. |
| --xunit-name         | string | Test name of xUnit. This is for colcon test integration. |

## Example

```txt
$ autoware-interface-check src/core/autoware_cmake/autoware_interface_check/example/interface.yaml
Test #0 (Success)
  message: OK
  details:
    schema: /home/user-name/autoware/install/autoware_interface_check/share/autoware_interface_check/example/schema/foo.schema.json
    params: /home/user-name/autoware/install/autoware_interface_check/share/autoware_interface_check/example/config/foo_success.param.yaml

Test #1 (Failure)
  message: 'frame' is a required property
  details:
    schema: /home/user-name/autoware/install/autoware_interface_check/share/autoware_interface_check/example/schema/foo.schema.json
    params: /home/user-name/autoware/install/autoware_interface_check/share/autoware_interface_check/example/config/foo_failure.param.yaml

Summary
  all    : 2
  success: 1
  failure: 1
  errors : 0
```
