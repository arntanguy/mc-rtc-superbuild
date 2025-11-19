# GetCommandPrefix(VAR WRITE_TO)
#
# Constructs a command prefix for forwarding environment variables to
# subseequent cmake invocations (add_custom_command, ExternalProject_Add, etc.).
#
# - VAR: Variable name to set in parent scope with the command prefix.
# - WRITE_TO: File path to write the environment prefix string.
#
# Behavior:
# - Collects environment variables (PATH, CMAKE_PREFIX_PATH, PKG_CONFIG_PATH, etc.).
# - Adds platform-specific variables (DYLD_LIBRARY_PATH, LD_LIBRARY_PATH).
# - Adds Python venv and ROS variables if relevant.
# - Escapes spaces in values.
# - Joins all variables into a single string and writes to WRITE_TO.
# - Sets VAR to: cmake -DCMAKE_PREFIX_FILE=<WRITE_TO> -P <cmake-with-prefix.cmake> --
#
# Usage:
#   GetCommandPrefix(COMMAND_PREFIX "/tmp/cmake-prefix.cmake")
#   # Use ${COMMAND_PREFIX} in custom commands or ExternalProject_Add.
#
function(GetCommandPrefix VAR WRITE_TO)
  if(NOT WIN32 OR NOT MC_RTC_SUPERBUILD_SET_ENVIRONMENT)
    set(CMAKE_COMMAND_PREFIX
        ${CMAKE_COMMAND} -E env PATH=$ENV{PATH}
        CMAKE_PREFIX_PATH=${CMAKE_INSTALL_PREFIX}/lib/cmake:$ENV{CMAKE_PREFIX_PATH}
        PKG_CONFIG_PATH=$ENV{PKG_CONFIG_PATH}
    )
  endif()
  if(APPLE)
    list(APPEND CMAKE_COMMAND_PREFIX DYLD_LIBRARY_PATH=$ENV{DYLD_LIBRARY_PATH})
  elseif(UNIX)
    list(APPEND CMAKE_COMMAND_PREFIX LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH})
  endif()
  if(VENV_PATH)
    list(APPEND CMAKE_COMMAND_PREFIX VIRTUAL_ENV=${VENV_PATH}
         PATH=${VENV_PATH}/bin:$ENV{PATH}
    )
  endif()
  if(WITH_ROS_SUPPORT)
    list(
      APPEND
      CMAKE_COMMAND_PREFIX
      ROS_DISTRO=$ENV{ROS_DISTRO}
      PYTHONPATH=$ENV{PYTHONPATH}
      ROS_ROOT=$ENV{ROS_ROOT}
      ROS_ETC_DIR=$ENV{ROS_ETC_DIR}
      ROS_PARALLEL_JOBS="$ENV{ROS_PARALLEL_JOBS}"
      ROS_VERSION="$ENV{ROS_VERSION}"
    )
    if(ROS_IS_ROS2)
      list(APPEND CMAKE_COMMAND_PREFIX AMENT_PREFIX_PATH=$ENV{AMENT_PREFIX_PATH}
           COLCON_PREFIX_PATH=$ENV{COLCON_PREFIX_PATH}
      )
    else()
      list(APPEND CMAKE_COMMAND_PREFIX ROS_PACKAGE_PATH=$ENV{ROS_PACKAGE_PATH})
    endif()
  else()
    if(NOT WIN32 OR NOT MC_RTC_SUPERBUILD_SET_ENVIRONMENT)
      list(APPEND CMAKE_COMMAND_PREFIX PYTHONPATH=$ENV{PYTHONPATH})
    endif()
  endif()
  if(UNIX AND ADD_PROJECT_ARGS_NO_COLOR)
    message(CONFIGURE_LOG "Disabling color output for ${NAME} build command")
    list(APPEND CMAKE_COMMAND_PREFIX CLICOLOR=0)
  endif()
  if(EMSCRIPTEN)
    list(
      PREPEND
      CMAKE_COMMAND_PREFIX
      ${CMAKE_COMMAND}
      -E
      env
      "CXXFLAGS=-matomics -s USE_PTHREADS=1 -s DISABLE_EXCEPTION_CATCHING=0"
      "LDFLAGS=-s USE_PTHREADS=1 -s DISABLE_EXCEPTION_CATCHING=0"
    )
  endif()
  list(TRANSFORM CMAKE_COMMAND_PREFIX REPLACE " " "\\\\ " OUTPUT_VARIABLE
                                                          CMAKE_COMMAND_PREFIX
  ) # restore backslash before spaces in env variables
  list(JOIN CMAKE_COMMAND_PREFIX " " CMAKE_COMMAND_PREFIX_STR)
  file(WRITE "${WRITE_TO}" ${CMAKE_COMMAND_PREFIX_STR})
  set(${VAR}
      ${CMAKE_COMMAND} -DCMAKE_PREFIX_FILE=${WRITE_TO} -P
      ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/scripts/cmake-with-prefix.cmake --
      PARENT_SCOPE
  )
endfunction()
