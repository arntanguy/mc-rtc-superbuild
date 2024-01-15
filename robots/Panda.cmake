option(WITH_Panda "Build Franka Emika Panda support" OFF)

set(Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT ON)
if(DPKG AND WITH_ROS_SUPPORT)
  if(ROS_IS_ROS2)
    set(Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT ON)
  else()
    set(Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT OFF)
  endif()
endif()
cmake_dependent_option(Panda_DEPENDENCIES_FROM_SOURCE "Install Panda dependencies from source" ${Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT} "WITH_Panda" OFF)

if(NOT WITH_Panda)
  return()
endif()

if(ROS_IS_ROS2)
  if(Panda_DEPENDENCIES_FROM_SOURCE)
    AddProject(libfranka
      GITHUB frankaemika/libfranka
      GIT_TAG origin/0.8.0-rc
    )
    set(mc_panda_DEPENDS libfranka)
    if(WITH_ROS_SUPPORT)
      AddCatkinProject(franka_ros2
        GITHUB frankaemika/franka_ros2
        GIT_TAG origin/humble
        WORKSPACE data_ws
        DEPENDS libfranka
      )
      list(APPEND mc_panda_DEPENDS franka_ros2)
    endif()
  else()
    message(FATAL_ERROR "Panda dependencies binaries are not yet available from ROS2 APT mirrors, set Panda_DEPENDENCIES_FROM_SOURCE to ON")
  endif()
else()
  if(Panda_DEPENDENCIES_FROM_SOURCE)
    AddProject(libfranka
      GITHUB frankaemika/libfranka
      GIT_TAG origin/0.8.0
    )
    set(mc_panda_DEPENDS libfranka)
    if(WITH_ROS_SUPPORT)
      AddCatkinProject(franka_ros
        GITHUB frankaemika/franka_ros
        GIT_TAG origin/0.8.1
        WORKSPACE data_ws
        DEPENDS libfranka
      )
      list(APPEND mc_panda_DEPENDS franka_ros)
    endif()
  else()
    if(NOT DPKG OR NOT WITH_ROS_SUPPORT)
      message(FATAL_ERROR "Panda dependencies binaries are only available from ROS APT mirrors, set Panda_DEPENDENCIES_FROM_SOURCE to OFF")
    endif()
    AptInstall(ros-${ROS_DISTRO}-libfranka ros-${ROS_DISTRO}-franka-description)
  endif()
endif()

AddProject(mc_panda
  GITHUB jrl-umi3218/mc_panda
  GIT_TAG origin/master
  DEPENDS mc_rtc ${mc_panda_DEPENDS}
)
