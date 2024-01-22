option(WITH_HC10DTP "Build Yaskawa HC10DTP support for mc_rtc" OFF)
option(WITH_HC10DTP_ROS_CONTROL "Build the ros_control interface for controlling HC10DTP robot" OFF)

if(NOT WITH_HC10DTP)
  return()
endif()

AddCatkinProject(hc10dtp_description
  GITE adennaoui/hc10dtp_description
  GIT_TAG origin/main
  WORKSPACE data_ws
)

AddProject(mc_hc10dtp
  GITE adennaoui/mc_hc10dtp
  GIT_TAG origin/master
  DEPENDS hc10dtp_description mc_rtc
)

if(WITH_HC10DTP_ROS_CONTROL)
  if(NOT WITH_HC10DTP)
    message(FATAL_ERROR "Cannot build WITH_HC10DTP_ROS_CONTROL without WITH_HC10DTP=ON")
  endif()

  AptInstall(ros-${ROS_DISTRO}-industrial-msgs ros-${ROS_DISTRO}-industrial-robot-client)

  AddCatkinProject(motoman
    GITHUB ros-industrial/motoman
    GIT_TAG origin/kinetic-devel
    WORKSPACE mc_rtc_ws
  )

  AddCatkinProject(mc_rtc_ros_control_yaskawa
    GITHUB arntanguy/mc_rtc_ros_control_yaskawa
    GIT_TAG origin/main
    WORKSPACE mc_rtc_ws
    DEPENDS mc_rtc
  )
endif()
