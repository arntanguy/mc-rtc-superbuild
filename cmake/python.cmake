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

macro(handle_conda_env ENV_NAME)
  # Set default paths and Python version
  set(MINICONDA_PATH "${CMAKE_INSTALL_PREFIX}/miniconda")
  set(CONDA_EXEC "${MINICONDA_PATH}/bin/conda")
  set(DEFAULT_PYTHON_VERSION "3.10")
  set(ENV{PYTHONPATH} "")

  # create MINICONDA_PATH if it doesn't exist
  execute_process(COMMAND mkdir -p ${CMAKE_INSTALL_PREFIX})

  # Check if conda exists
  execute_process(
    COMMAND ${CONDA_EXEC} --version
    RESULT_VARIABLE CONDA_EXISTS
    OUTPUT_QUIET ERROR_QUIET
  )
  if(NOT CONDA_EXISTS EQUAL 0)
    message(STATUS "Conda not found, installing Miniconda...")
    set(MINICONDA_INSTALLER "${CMAKE_INSTALL_PREFIX}/miniconda.sh")
    message(STATUS "Miniconda installer path: ${MINICONDA_INSTALLER}")
    # Download Miniconda installer
    execute_process(
      COMMAND wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
              -O ${MINICONDA_INSTALLER} RESULT_VARIABLE WGET_RESULT
    )
    if(NOT WGET_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to download Miniconda installer")
    endif()
    # Run Miniconda installer
    execute_process(
      COMMAND bash ${MINICONDA_INSTALLER} -b -p ${MINICONDA_PATH}
      RESULT_VARIABLE INSTALL_RESULT
    )
    if(NOT INSTALL_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to install Miniconda")
    endif()
  endif()

  # Check if the conda environment exists
  execute_process(
    COMMAND ${CONDA_EXEC} env list
    OUTPUT_VARIABLE CONDA_ENVS
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  string(FIND "${CONDA_ENVS}" "${ENV_NAME}" ENV_FOUND)
  if(ENV_FOUND EQUAL -1)
    message(
      STATUS
        "Creating conda environment '${ENV_NAME}' with Python ${DEFAULT_PYTHON_VERSION}"
    )
    # Accept Anaconda Terms of Service for required channels
    execute_process(
      COMMAND ${CONDA_EXEC} tos accept --override-channels --channel
              https://repo.anaconda.com/pkgs/main
      RESULT_VARIABLE TOS_MAIN_RESULT
      OUTPUT_QUIET ERROR_QUIET
    )
    execute_process(
      COMMAND ${CONDA_EXEC} tos accept --override-channels --channel
              https://repo.anaconda.com/pkgs/r
      RESULT_VARIABLE TOS_R_RESULT
      OUTPUT_QUIET ERROR_QUIET
    )
    execute_process(
      COMMAND ${CONDA_EXEC} create -y -n ${ENV_NAME} python=3.10
      RESULT_VARIABLE CONDA_CREATE_RESULT
    )
    if(NOT CONDA_CREATE_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to create conda environment '${ENV_NAME}'")
    endif()
  else()
    message(STATUS "Conda environment '${ENV_NAME}' already exists")
  endif()

  # ROS2
  # message(STATUS "Installing ROS 2 Jazzy in conda environment '${ENV_NAME}'")
  # execute_process(
  #   COMMAND ${CONDA_EXEC} install -y -n ${ENV_NAME} -c robostack -c conda-forge ros-jazzy-desktop
  #   RESULT_VARIABLE ROS_INSTALL_RESULT
  # )
  # if(NOT ROS_INSTALL_RESULT EQUAL 0)
  #   message(FATAL_ERROR "Failed to install ROS 2 Jazzy in conda environment '${ENV_NAME}'")
  # endif()

  # Get the path to the conda environment
  execute_process(
    COMMAND ${CONDA_EXEC} info --base
    OUTPUT_VARIABLE CONDA_BASE
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  set(CONDA_ENV_PATH "${CONDA_BASE}/envs/${ENV_NAME}")

  # Set Python and pip paths
  set(MC_RTC_SUPERBUILD_DEFAULT_PYTHON
      "${CONDA_ENV_PATH}/bin/python"
      CACHE INTERNAL ""
  )
  set(MC_RTC_SUPERBUILD_DEFAULT_PIP
      "${CONDA_ENV_PATH}/bin/pip"
      CACHE INTERNAL ""
  )

  # # Set environment variables for subprocesses
  # set(CONDA_ENV_PATH "${CONDA_BASE}/envs/${ENV_NAME}")
  #
  # # Prepend conda env bin to PATH for all subprocesses
  # set(ENV{PATH} "${CONDA_ENV_PATH}/bin:$ENV{PATH}")
  # set(ENV{CONDA_DEFAULT_ENV} "${ENV_NAME}")
  # set(ENV{CONDA_PREFIX} "${CONDA_ENV_PATH}")

  # Use these paths for Python and pip in further commands
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
