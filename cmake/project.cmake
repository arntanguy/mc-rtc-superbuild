include(cmake/options.cmake)
include(cmake/setup-env.cmake)
include(cmake/sudo.cmake)

include(CMakeDependentOption)
include(ExternalProject)

# Wrapper around the ExternalProject_Add function to allow simplified usage
#
# Options
# =======
#
# - SKIP_TEST Do not run tests
# - NO_NINJA Indicate that the project is not compatible with the Ninja generator
# - GIT_USE_SSH Use SSH for cloning/updating git repository for GITHUB/GITE repos
# - GITHUB <org/project> Use https://github.com/org/project as GIT_REPOSITORY
# - GITE <org/project> Use https://gite.lirmm.fr/org/project as GIT_REPOSITORY
#
# Variables
# =========
#
# - GLOBAL_DEPENDS those projects are added to every project dependencies
#

function(AddProject NAME)
  if(TARGET ${NAME})
    return()
  endif()
  set(options NO_NINJA GIT_USE_SSH SKIP_TEST)
  set(oneValueArgs GITHUB GITE GIT_REPOSITORY GIT_TAG SOURCE_DIR)
  set(multiValueArgs CMAKE_ARGS BUILD_COMMAND CONFIGURE_COMMAND INSTALL_COMMAND DEPENDS)
  cmake_parse_arguments(ADD_PROJECT_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  # Handle NO_NINJA
  if(NOT WIN32)
    if(ADD_PROJECT_ARGS_NO_NINJA)
      set(GENERATOR "Unix Makefiles")
    else()
      set(GENERATOR "Ninja")
    endif()
  else()
    set(GENERATOR "${CMAKE_GENERATOR}")
  endif()
  # Handle GITHUB
  if(ADD_PROJECT_ARGS_GITHUB)
    set(GIT_REPOSITORY "${ADD_PROJECT_ARGS_GITHUB}")
    if(ADD_PROJECT_ARGS_GIT_USE_SSH)
      set(GIT_REPOSITORY "git@github.com:${GIT_REPOSITORY}")
    else()
      set(GIT_REPOSITORY "https://github.com/${GIT_REPOSITORY}")
    endif()
  endif()
  # Handle GITE
  if(ADD_PROJECT_ARGS_GITE)
    if(DEFINED GIT_REPOSITORY)
      message(FATAL_ERROR "Only one of GITHUB/GITE/GIT_REPOSITORY must be provided")
    endif()
    set(GIT_REPOSITORY "${ADD_PROJECT_ARGS_GITE}")
    if(ADD_PROJECT_ARGS_GIT_USE_SSH)
      set(GIT_REPOSITORY "git@gite.lirmm.fr:${GIT_REPOSITORY}")
    else()
      set(GIT_REPOSITORY "https://gite.lirmm.fr/${GIT_REPOSITORY}")
    endif()
  endif()
  # Handle GIT_REPOSITORY
  if(ADD_PROJECT_ARGS_GIT_REPOSITORY)
    if(DEFINED GIT_REPOSITORY)
      message(FATAL_ERROR "Only one of GITHUB/GITE/GIT_REPOSITORY must be provided")
    endif()
    set(GIT_REPOSITORY "${ADD_PROJECT_ARGS_GIT_REPOSITORY}")
  endif()
  # Handle GIT_TAG
  if(ADD_PROJECT_ARGS_GIT_TAG)
    set(GIT_TAG "${ADD_PROJECT_ARGS_GIT_TAG}")
  else()
    set(GIT_TAG "main")
  endif()
  set(CMAKE_ARGS)
  if(ADD_PROJECT_ARGS_CMAKE_ARGS)
    set(CMAKE_ARGS "${ADD_PROJECT_ARGS_CMAKE_ARGS}")
  endif()
  list(PREPEND CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON"
    "-DINSTALL_DOCUMENTATION:BOOL=${INSTALL_DOCUMENTATION}"
    "-DPYTHON_BINDING:BOOL=${PYTHON_BINDING}"
    "-DPYTHON_BINDING_USER_INSTALL:BOOL=${PYTHON_BINDING_USER_INSTALL}"
    "-DPYTHON_BINDING_FORCE_PYTHON2:BOOL=${PYTHON_BINDING_FORCE_PYTHON2}"
    "-DPYTHON_BINDING_FORCE_PYTHON3:BOOL=${PYTHON_BINDING_FORCE_PYTHON3}"
    "-DPYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3:BOOL=${PYTHON_BINDING_BUILD_PYTHON2_AND_PYTHON3}"
  )
  if(WIN32)
    list(PREPEND CMAKE_ARGS
      "-DBOOST_ROOT=${BOOST_ROOT}"
    )
  endif()
  if(DEFINED CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    list(PREPEND CMAKE_ARGS "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
  endif()
  if(ADD_PROJECT_ARGS_SKIP_TEST)
    list(PREPEND CMAKE_ARGS
      "-DBUILD_TESTING:BOOL=OFF"
    )
  endif()
  cmake_dependent_option(UPDATE_${NAME} "Update ${NAME}" ON "UPDATE_ALL" OFF)
  if(UPDATE_${NAME})
    set(UPDATE_DISCONNECTED OFF)
  else()
    set(UPDATE_DISCONNECTED ON)
  endif()
  if(ADD_PROJECT_ARGS_SOURCE_DIR)
    set(SOURCE_DIR "${ADD_PROJECT_ARGS_SOURCE_DIR}")
  else()
    set(SOURCE_DIR "${SOURCE_DESTINATION}/${NAME}")
  endif()
  set(BINARY_DIR "${PROJECT_BINARY_DIR}/build/${NAME}")
  if(NOT WIN32 OR NOT MC_RTC_SUPERBUILD_SET_ENVIRONMENT)
    set(COMMAND_PREFIX ${CMAKE_COMMAND} -E env PATH=$ENV{PATH} CMAKE_PREFIX_PATH=$ENV{CMAKE_PREFIX_PATH} PKG_CONFIG_PATH=$ENV{PKG_CONFIG_PATH})
  endif()
  if(APPLE)
    list(APPEND COMMAND_PREFIX DYLD_LIBRARY_PATH=$ENV{DYLD_LIBRARY_PATH})
  elseif(UNIX)
    list(APPEND COMMAND_PREFIX LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH})
  endif()
  if(WITH_ROS_SUPPORT)
    list(APPEND COMMAND_PREFIX ROS_PACKAGE_PATH=$ENV{ROS_PACKAGE_PATH} ROS_DISTRO=$ENV{ROS_DISTRO} PYTHONPATH=$ENV{PYTHONPATH} ROS_ROOT=$ENV{ROS_ROOT} ROS_ETC_DIR=$ENV{ROS_ETC_DIR})
  endif()
  # -- Configure command
  if(NOT ADD_PROJECT_ARGS_CONFIGURE_COMMAND AND NOT CONFIGURE_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES)
    set(CONFIGURE_COMMAND ${COMMAND_PREFIX} ${CMAKE_COMMAND} -G "${GENERATOR}" -B "${BINARY_DIR}" -S "${SOURCE_DIR}" ${CMAKE_ARGS})
  else()
    if("${ADD_PROJECT_ARGS_CONFIGURE_COMMAND}" STREQUAL "")
      set(CONFIGURE_COMMAND ${CMAKE_COMMAND} -E true)
    else()
      set(CONFIGURE_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_CONFIGURE_COMMAND})
    endif()
  endif()
  # -- Build command
  if(NOT ADD_PROJECT_ARGS_BUILD_COMMAND AND NOT BUILD_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES)
    set(BUILD_COMMAND ${COMMAND_PREFIX} ${CMAKE_COMMAND} --build . --config $<CONFIG>)
  else()
    if("${ADD_PROJECT_ARGS_BUILD_COMMAND}" STREQUAL "")
      set(BUILD_COMMAND ${CMAKE_COMMAND} -E true)
    else()
      set(BUILD_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_BUILD_COMMAND})
    endif()
  endif()
  # -- Install command
  if(NOT ADD_PROJECT_ARGS_INSTALL_COMMAND AND NOT INSTALL_COMMAND IN_LIST ADD_PROJECT_ARGS_KEYWORDS_MISSING_VALUES)
    set(INSTALL_COMMAND  ${CMAKE_COMMAND} --build ${BINARY_DIR} --target install --config $<CONFIG>)
  else()
    if("${ADD_PROJECT_ARGS_INSTALL_COMMAND}" STREQUAL "")
      set(INSTALL_COMMAND "")
    else()
      set(INSTALL_COMMAND ${COMMAND_PREFIX} ${ADD_PROJECT_ARGS_INSTALL_COMMAND})
    endif()
  endif()
  if(USE_SUDO AND NOT "${INSTALL_COMMAND}" STREQUAL "")
    set(INSTALL_COMMAND ${SUDO_CMD} -E ${INSTALL_COMMAND})
    if(NOT DEFINED ENV{USER})
      execute_process(COMMAND whoami OUTPUT_VARIABLE USER OUTPUT_STRIP_TRAILING_WHITESPACE)
    else()
      set(USER $ENV{USER})
    endif()
    if(NOT ADD_PROJECT_ARGS_NO_NINJA)
      set(EXTRA_INSTALL_COMMAND COMMAND /bin/bash -c "${SUDO_CMD} chown -f ${USER} ${BINARY_DIR}/.ninja_deps ${BINARY_DIR}/.ninja_log || true")
    endif()
  endif()
  if(INSTALL_COMMAND STREQUAL "")
    set(INSTALL_COMMAND ${CMAKE_COMMAND} -E true)
  endif()
  # -- Test command
  if(NOT ADD_PROJECT_ARGS_SKIP_TEST)
    set(TEST_STEP_OPTIONS TEST_AFTER_INSTALL TRUE TEST_COMMAND ${COMMAND_PREFIX} ctest -C $<CONFIG>)
  endif()
  # -- Depends option
  list(APPEND ADD_PROJECT_ARGS_DEPENDS ${GLOBAL_DEPENDS})
  set(DEPENDS DEPENDS ${ADD_PROJECT_ARGS_DEPENDS})
  # -- CLONE_ONLY option
  if(CLONE_ONLY)
    set(CONFIGURE_COMMAND ${CMAKE_COMMAND} -E true)
    set(BUILD_COMMAND ${CMAKE_COMMAND} -E true)
    set(INSTALL_COMMAND ${CMAKE_COMMAND} -E true)
    set(EXTRA_INSTALL_COMMAND "")
    set(TEST_STEP_OPTIONS TEST_AFTER_INSTALL FALSE TEST_BEFORE_INSTALL FALSE TEST_COMMAND ${CMAKE_COMMAND} -E true)
  endif()
  if(MC_RTC_SUPERBUILD_VERBOSE)
    message("=============== ${NAME} ===============")
    message("SOURCE_DIR: ${SOURCE_DIR}")
    message("BINARY_DIR: ${BINARY_DIR}")
    message("GIT_REPOSITORY: ${GIT_REPOSITORY}")
    message("GIT_TAG: ${GIT_TAG}")
    message("UPDATE_DISCONNECTED: ${UPDATE_DISCONNECTED}")
    message("CONFIGURE_COMMAND IS: ${CONFIGURE_COMMAND}")
    message("BUILD_COMMAND IS: ${BUILD_COMMAND}")
    message("INSTALL_COMMAND IS: ${INSTALL_COMMAND}")
    message("EXTRA_INSTALL_COMMAND IS: ${EXTRA_INSTALL_COMMAND}")
    message("TEST_STEP_OPTIONS: ${TEST_STEP_OPTIONS}")
    message("DEPENDS: ${DEPENDS}")
    message("UNPARSED_ARGUMENTS: ${ADD_PROJECT_ARGS_UNPARSED_ARGUMENTS}")
  endif()
  ExternalProject_Add(${NAME}
    SOURCE_DIR ${SOURCE_DIR}
    BINARY_DIR ${BINARY_DIR}
    GIT_REPOSITORY ${GIT_REPOSITORY}
    GIT_TAG ${GIT_TAG}
    UPDATE_DISCONNECTED ${UPDATE_DISCONNECTED}
    CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
    BUILD_COMMAND ${BUILD_COMMAND}
    INSTALL_COMMAND ${INSTALL_COMMAND}
    ${EXTRA_INSTALL_COMMAND}
    USES_TERMINAL_INSTALL TRUE
    ${TEST_STEP_OPTIONS}
    ${DEPENDS}
    ${ADD_PROJECT_ARGS_UNPARSED_ARGUMENTS}
  )
  # This step forces CMake to re-run configure/build/install when the source content changes
  file(GLOB_RECURSE ${NAME}_SOURCES CONFIGURE_DEPENDS "${SOURCE_DIR}/*")
  ExternalProject_Add_Step(${NAME} check-sources
    DEPENDEES patch
    DEPENDERS configure
    DEPENDS ${${NAME}_SOURCES}
  )
endfunction()

# Wrapper around AddProject
#
# Options
# =======
#
# - WORKSPACE Catkin workspace where the project is cloned, this option is required
function(AddCatkinProject NAME)
  set(options)
  set(oneValueArgs WORKSPACE)
  set(multiValueArgs)
  cmake_parse_arguments(ADD_CATKIN_PROJECT_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  if(NOT ADD_CATKIN_PROJECT_ARGS_WORKSPACE)
    message(FATAL_ERROR "WORKSPACE must be provided when calling AddCatkinProject")
  endif()
  set(WORKSPACE "${ADD_CATKIN_PROJECT_ARGS_WORKSPACE}")
  if(WITH_ROS_SUPPORT)
    AddProject(${NAME}
      SOURCE_DIR "${WORKSPACE}/src/${NAME}"
      CONFIGURE_COMMAND ""
      BUILD_COMMAND catkin_make -C "${WORKSPACE}" -DCMAKE_BUILD_TYPE=$<CONFIG>
      INSTALL_COMMAND ""
      SKIP_TEST
      ${ADD_CATKIN_PROJECT_ARGS_UNPARSED_ARGUMENTS}
    )
  else()
    AddProject(${NAME}
      ${ADD_CATKIN_PROJECT_ARGS_UNPARSED_ARGUMENTS}
    )
  endif()
endfunction()
