AddProject(
  mesh_sampling  
  GITHUB_PRIVATE jrl-umi3218/mesh_sampling
  GIT_TAG origin/master
  APT_PACKAGES mesh_sampling
  APT_DEPENDENCIES libpcl-dev libassimp-dev libeigen3-dev libboost-program-options-dev libboost-filesystem-dev
)

AddProject(
  mc_robot_tools
  GITHUB_PRIVATE arntanguy/mc_robot_tools
  GIT_TAG origin/topic/optional 
  DEPENDS mesh_sampling mc_rtc
  APT_DEPENDENCIES qhull-bin 
  CMAKE_ARGS -DWITH_INTERFACES=OFF -DWITH_TOOLS=OFF -DINSTALL_3rd_PARTY=OFF
)

AddProject(
  exo_hri
  GITE msun/exo_hri
  GIT_TAG origin/main 
)

AddProject(
  exo_hri_controller
  GITE atanguy/exo_hri_controller
  GIT_TAG origin/main
)

# Plugin to update the size of the human model
# AddProject(mc_robot_model_update
#   GITHUB Hugo-L3174/mc_robot_model_update
#   GIT_TAG origin/main
#   DEPENDS mc_rtc
# )

# Human model
AddCatkinProject(human_description
  GITE hlefevre/human_description
  GIT_TAG origin/master
  WORKSPACE data_ws
)

# Robot module for human model
AddProject(mc_human
  GITE hlefevre/mc_human
  GIT_TAG origin/master
  DEPENDS human_description mc_rtc
)

# mc-rtc-magnum
AddProject(mc_rtc-magnum
  GITHUB arntanguy/mc_rtc-magnum
  GIT_TAG origin/main
  DEPENDS mc_rtc
  APT_DEPENDENCIES libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libassimp-dev
)
