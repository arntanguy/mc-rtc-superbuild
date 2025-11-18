# Usage example (after DISTRO and MC_RTC_SUPERBUILD_DEFAULT_PYTHON are set):
# handle_noble_virtualenv(${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} ${DISTRO})
macro(handle_noble_virtualenv PYTHON_EXEC DISTRO)
  if(${DISTRO} STREQUAL "noble")
    # Check if we are already in a virtualenv
    execute_process(
      COMMAND
        ${PYTHON_EXEC} -c
        "import sys; exit(0) if (hasattr(sys, 'real_prefix') or (getattr(sys, 'base_prefix', sys.prefix) != sys.prefix)) else exit(1)"
      RESULT_VARIABLE IN_VENV # 0 if in venv, 1 otherwise
    )
    if(IN_VENV EQUAL 0 # we are in a venv
       AND ENV{VIRTUAL_ENV} STREQUAL
           ${MC_RTC_SUPERBUILD_VENV_NAME} # and the active venv matches the expected one
    )
      message(
        STATUS
          "Already in the expected Python virtualenv: ${MC_RTC_SUPERBUILD_VENV_NAME}"
      )
    else()
      set(VENV_PATH "${CMAKE_INSTALL_PREFIX}/${MC_RTC_SUPERBUILD_VENV_NAME}")
      message(STATUS "Creating Python virtualenv at ${VENV_PATH} for Ubuntu Noble")
      execute_process(
        COMMAND ${PYTHON_EXEC} -m venv "${VENV_PATH}" RESULT_VARIABLE VENV_RESULT
      )
      if(NOT VENV_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to create Python virtualenv at ${VENV_PATH}")
      endif()
      # Re-execute python from the venv for subsequent pip installs
      set(MC_RTC_SUPERBUILD_DEFAULT_PYTHON
          "${VENV_PATH}/bin/python"
          CACHE INTERNAL ""
      )
      # "Activate" the venv for subsequent commands by setting Python and pip paths
      set(MC_RTC_SUPERBUILD_DEFAULT_PIP
          "${VENV_PATH}/bin/pip"
          CACHE INTERNAL ""
      )
      # set environment variables for subprocesses
      set(ENV{VIRTUAL_ENV} "${VENV_PATH}")
      set(ENV{PATH} "${VENV_PATH}/bin:$ENV{PATH}")
    endif()
  endif()
endmacro()

# filepath: /home/vscode/superbuild/cmake/python.cmake
macro(handle_conda_env ENV_NAME)
  # Set default paths and Python version
  set(MICROMAMBA_PATH "${CMAKE_INSTALL_PREFIX}/micromamba")
  set(MICROMAMBA_BIN "${MICROMAMBA_PATH}/bin/micromamba")
  #set(DEFAULT_PYTHON_VERSION "3.10")
  set(DEFAULT_PYTHON_VERSION "3.9")
  set(ENV{PYTHONPATH} "")

  # Create MICROMAMBA_PATH/bin if it doesn't exist
  execute_process(COMMAND mkdir -p ${MICROMAMBA_PATH}/bin)

  # Download micromamba if not present
  if(NOT EXISTS ${MICROMAMBA_BIN})
    message(STATUS "Micromamba not found, installing with curl and tar...")
    execute_process(
      COMMAND
        bash -c
        "mkdir -p ${MICROMAMBA_PATH} && curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C ${MICROMAMBA_PATH} bin/micromamba"
      RESULT_VARIABLE INSTALL_RESULT
    )
    if(NOT INSTALL_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to install micromamba with curl and tar")
    endif()
  endif()

  # Set MAMBA_ROOT_PREFIX for micromamba
  set(MAMBA_ROOT_PREFIX "${MICROMAMBA_PATH}")

  # Check if the conda environment exists
  execute_process(
    COMMAND ${MICROMAMBA_BIN} env list --root-prefix ${MAMBA_ROOT_PREFIX}
    OUTPUT_VARIABLE CONDA_ENVS
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  string(FIND "${CONDA_ENVS}" "${ENV_NAME}" ENV_FOUND)
  if(ENV_FOUND EQUAL -1)
    message(
      STATUS
        "Creating conda environment '${ENV_NAME}' with Python ${DEFAULT_PYTHON_VERSION}"
    )
    execute_process(
      COMMAND ${MICROMAMBA_BIN} create -y -n ${ENV_NAME} -r ${MAMBA_ROOT_PREFIX}
              python=${DEFAULT_PYTHON_VERSION} -c conda-forge gcc
      RESULT_VARIABLE CONDA_CREATE_RESULT
    )
    if(NOT CONDA_CREATE_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to create conda environment '${ENV_NAME}'")
    endif()

    message(STATUS "Installing build tools conda environment '${ENV_NAME}'")
    execute_process(
      COMMAND ${MICROMAMBA_BIN} install -y -n ${ENV_NAME} -c conda-forge compilers cmake
              pkg-config make ninja RESULT_VARIABLE INSTALL_RESULT
    )
    if(NOT INSTALL_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to install build tools in ${ENV_NAME}")
    endif()
  else()
    message(STATUS "Conda environment '${ENV_NAME}' already exists")
  endif()

  execute_process(
    COMMAND ${MICROMAMBA_BIN} install -y -n ${ENV_NAME} -c conda-forge -c robostack-humble ros-humble-desktop
    RESULT_VARIABLE INSTALL_RESULT
  )
  if(NOT INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install ros-humble-desktop in ${ENV_NAME}")
  endif()


  # Set Python and pip paths
  set(CONDA_ENV_PATH "${MAMBA_ROOT_PREFIX}/envs/${ENV_NAME}")
  set(ENV{CONDA_DEFAULT_ENV} "${ENV_NAME}")
  set(MC_RTC_SUPERBUILD_DEFAULT_PYTHON
      "${CONDA_ENV_PATH}/bin/python"
      CACHE INTERNAL ""
  )
  set(MC_RTC_SUPERBUILD_DEFAULT_PIP
      "${CONDA_ENV_PATH}/bin/pip"
      CACHE INTERNAL ""
  )

  set(ENV{PATH} "${CONDA_ENV_PATH}/bin:$ENV{PATH}")
  set(ENV{CONDA_PREFIX} "${CONDA_ENV_PATH}")
  set(ENV{PYTHONPATH} "${CONDA_ENV_PATH}/lib/${DEFAULT_PYTHON_VERSION}/site-packages:$ENV{PYTHONPATH}")

  set(MC_RTC_SUPERBUILD_DEFAULT_PYTHON "${CONDA_ENV_PATH}/bin/python")
  message(STATUS "Using Python executable: ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON}")
  execute_process(
    COMMAND
      ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} -c
      "import sys; print(\"python{}.{}\".format(sys.version_info.major, sys.version_info.minor));"
    OUTPUT_VARIABLE PYTHON_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  message(STATUS "Using Python version: ${PYTHON_VERSION}")
endmacro()
# ...existing code...

execute_process(
  COMMAND
    ${MC_RTC_SUPERBUILD_DEFAULT_PYTHON} -c
    "import sys; print(\"python{}.{}\".format(sys.version_info.major, sys.version_info.minor));"
  OUTPUT_VARIABLE PYTHON_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "Using Python version: ${PYTHON_VERSION}")

set(ENV{PYTHONPATH}
    "${CMAKE_INSTALL_PREFIX}/lib/${PYTHON_VERSION}/site-packages:$ENV{PYTHONPATH}"
)
