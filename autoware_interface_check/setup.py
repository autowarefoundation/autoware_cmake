from warnings import simplefilter

from pkg_resources import PkgResourcesDeprecationWarning
from setuptools import SetuptoolsDeprecationWarning
from setuptools import setup

simplefilter("ignore", category=SetuptoolsDeprecationWarning)
simplefilter("ignore", category=PkgResourcesDeprecationWarning)

package_name = "autoware_interface_check"

setup(
    name=package_name,
    version="0.47.0",
    packages=[package_name],
    data_files=[
        ("share/ament_index/resource_index/packages", [f"resource/{package_name}"]),
        (f"share/{package_name}", ["package.xml"]),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="Takagi, Isamu",
    maintainer_email="isamu.takagi@tier4.jp",
    description="Tools for interface check",
    license="Apache License 2.0",
    tests_require=["pytest", "jsonschema"],
    entry_points={
        "console_scripts": [
            "autoware-interface-check = autoware_interface_check.entrypoint:main",
        ]
    },
)
