option(WITH_Panda "Build Franka Emika Panda support" OFF)
option(WITH_PandaLIRMM "Build Panda support for LIRMM robots" OFF)
if(WITH_PandaLIRMM AND NOT WITH_Panda)
  message(FATAL_ERROR "Panda LIRMM support requires Panda support")
endif()

set(Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT ON)
if(DPKG AND WITH_ROS_SUPPORT)
  set(Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT OFF)
endif()
cmake_dependent_option(Panda_DEPENDENCIES_FROM_SOURCE "Install Panda dependencies from source" ${Panda_DEPENDENCIES_FROM_SOURCE_DEFAULT} "WITH_Panda" OFF)

if(NOT WITH_Panda)
  return()
endif()

if(Panda_DEPENDENCIES_FROM_SOURCE)
  # The latest version of the robot server we can have at CNRS-LIRMM is 4.2.2
  # According to the compability table: https://frankaemika.github.io/docs/compatibility.html
  # This means that we can use libfranka >= 0.9.1 < 0.10.0
  #
  # However with any of these version the TSan unit test fails. Despite this
  # it works on the real robot so we have simply disabled the unit tests here
  AddProject(libfranka
    GITHUB frankaemika/libfranka
    GIT_TAG 0.9.2
    CMAKE_ARGS -DBUILD_TESTS=OFF
  )
  set(mc_panda_DEPENDS libfranka)
  if(WITH_ROS_SUPPORT)
    if(ROS_IS_ROS2)
      CreateCatkinWorkspace(
	      ID franka_ws
	      DIR catkin_ws_franka
	      CATKIN_MAKE
	      CATKIN_BUILD_ARGS --packages-skip joint_trajectory_controller franka_hardware franka_semantic_components franka_gripper franka_msgs franka_moveit_config franka_robot_state_broadcaster franka_example_controllers franka_bringup
      )
      AddCatkinProject(franka_ros2
        GITHUB frankaemika/franka_ros2
        GIT_TAG origin/humble
        WORKSPACE franka_ws
        DEPENDS libfranka
      )
      list(APPEND mc_panda_DEPENDS franka_ros2)
    else()
      AddCatkinProject(franka_ros
        GITHUB frankaemika/franka_ros
        GIT_TAG origin/0.8.1
        WORKSPACE mc_rtc_ws
        DEPENDS libfranka
      )
      list(APPEND mc_panda_DEPENDS franka_ros)
    endif()
  endif()
else()
  if(NOT DPKG OR NOT WITH_ROS_SUPPORT)
    message(FATAL_ERROR "Panda dependencies binaries are only available from ROS APT mirrors, set Panda_DEPENDENCIES_FROM_SOURCE to OFF")
  endif()
  AptInstall(ros-${ROS_DISTRO}-libfranka ros-${ROS_DISTRO}-franka-description)
endif()

AddProject(mc_panda
  GITHUB jrl-umi3218/mc_panda
  GIT_TAG origin/master
  DEPENDS mc_rtc ${mc_panda_DEPENDS}
)

AddProject(mc_franka
  GITHUB jrl-umi3218/mc_franka
  GIT_TAG origin/master
  DEPENDS mc_rtc mc_panda
)

if(WITH_PandaLIRMM)
  AddProject(mc_panda_lirmm
    GITHUB jrl-umi3218/mc_panda_lirmm
    GIT_TAG origin/main
    DEPENDS mc_panda
  )
endif()
