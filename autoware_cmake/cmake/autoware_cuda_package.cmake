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

macro(autoware_cuda_package)
  autoware_package()

  find_package(CUDA)

  if(NOT ${CUDA_FOUND})
    message(WARNING "CUDA not found!")
    return()
  endif()

  # Detect local GPU architecture
  execute_process(
    COMMAND nvidia-smi --query-gpu=compute_cap --format=csv,noheader # cSpell:ignore noheader
    OUTPUT_VARIABLE LOCAL_GPU_ARCH
    ERROR_VARIABLE LOCAL_GPU_ARCH_ERR
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  # cSpell:ignore gencode
  if(LOCAL_GPU_ARCH)
    string(REPLACE "." "" LOCAL_GPU_ARCH "${LOCAL_GPU_ARCH}")
    message(STATUS "Found local GPU with compute capability: ${LOCAL_GPU_ARCH}")
    list(APPEND CUDA_NVCC_FLAGS "-gencode arch=compute_${LOCAL_GPU_ARCH},code=sm_${LOCAL_GPU_ARCH}")
  else()
    message(STATUS "No local GPU found, using common architectures with respect to Autoware CUDA version")
    # Common modern GPU architectures
    list(APPEND CUDA_NVCC_FLAGS "-gencode arch=compute_75,code=sm_75") # Turing (RTX 20 series)
    list(APPEND CUDA_NVCC_FLAGS "-gencode arch=compute_86,code=sm_86") # Ampere (RTX 30 series)
    list(APPEND CUDA_NVCC_FLAGS "-gencode arch=compute_87,code=sm_87") # Ampere (Jetson Orin series)
    list(APPEND CUDA_NVCC_FLAGS "-gencode arch=compute_89,code=sm_89") # Ada Lovelace (RTX 40 series)
    # PTX for forward compatibility
    list(APPEND CUDA_NVCC_FLAGS "-gencode arch=compute_89,code=compute_89")
  endif()

endmacro()
