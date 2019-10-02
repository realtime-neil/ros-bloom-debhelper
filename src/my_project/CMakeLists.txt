cmake_minimum_required(VERSION 3.0.2)
project(my_project)

# dpkg assumes multiarch and cmake supports it:
# https://wiki.debian.org/Multiarch/Implementation#Dynamic_debian.2F.2A_files
# https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 11)

add_compile_options(-Wall -Wextra -Werror -fPIC)

find_package(catkin REQUIRED COMPONENTS)

# https://github.com/ros/cmake_modules
find_package(cmake_modules REQUIRED)

catkin_package(
  CATKIN_DEPENDS
  DEPENDS
)

# because underscores in an executable basename look weird
string(REPLACE "_" "-" EXE_NAME "${PROJECT_NAME}")
add_executable(${EXE_NAME} src/main.cpp)

# because ROS_DISTRO is an env var, not (yet) a cmake var
if ("" STREQUAL "$ENV{ROS_DISTRO}")
  message(FATAL_ERROR "undefined env var ROS_DISTRO")
endif()
set(ROS_DISTRO "$ENV{ROS_DISTRO}")

# because it's handy to have the debian package name
string(REPLACE "_" "-" PACKAGE_NAME "ros-${ROS_DISTRO}-${PROJECT_NAME}")

# rsyslog filter rule - because debhelper can't do this (yet)
configure_file(
  etc/rsyslog.d/99-slug.conf.in
  etc/rsyslog.d/99-${PACKAGE_NAME}.conf
  @ONLY
)
install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/etc/rsyslog.d/99-${PACKAGE_NAME}.conf
  DESTINATION ${CMAKE_INSTALL_FULL_SYSCONFDIR}/rsyslog.d/
)

# https://wiki.ros.org/catkin/CMakeLists.txt#Installing_roslaunch_Files_or_Other_Resources
install(
  FILES launch/main.launch
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/launch
)

# > type="nodetype"
# >     Node type. There must be a corresponding executable with the same name.
#
# -- https://wiki.ros.org/roslaunch/XML/node
#
# Yep, it has to be an executable, but that executable must be installed to the
# CATKIN_PACKAGE_BIN_DESTINATION. `roslaunch` only finds executables installed
# to the CATKIN_PACKAGE_BIN_DESTINATION and definitely NOT the
# CATKIN_GLOBAL_BIN_DESTINATION. Because of course it does.
install(
  TARGETS ${EXE_NAME}
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

# take a script; make it a custom command and custom target
function(script_command_target script)
  add_custom_command(
    OUTPUT ${script}.errout
    DEPENDS ${script}
    COMMAND ${script} 2>&1 | tee ${script}.errout
    COMMENT ${script} 2>&1 | tee ${script}.errout
  )
  string(MAKE_C_IDENTIFIER ${script}.errout script_errout)
  add_custom_target(${script_errout} ALL DEPENDS ${script}.errout)
endfunction()

# take a target and desired capabilities; create *-setcap shell scripts for it
# under devel and install; invoke each at the proper time
function(setcap target capabilities)
  # generate target setcap script into devel space
  set(SETCAP_CAPABILITIES ${capabilities})
  configure_file(
    bin/setcap.slug.in
    ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_BIN_DESTINATION}/${target}-setcap
    @ONLY
  )

  # install target setcap script from devel space
  install(
    PROGRAMS ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_BIN_DESTINATION}/${target}-setcap
    DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
  )

  # invoke the devel target setcap script
  script_command_target(${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_BIN_DESTINATION}/${target}-setcap)

  # invoke the install target setcap script
  install(CODE
    "
    set(
      installed_script
      \$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/${CATKIN_PACKAGE_BIN_DESTINATION}/${target}-setcap
    )
    execute_process(
      COMMAND \${installed_script}
      RESULT_VARIABLE installed_script_res
    )
    if(NOT installed_script_res EQUAL 0)
      message(FATAL_ERROR \"FAILURE: \${installed_script}\")
    endif()
    "
  )
endfunction()

setcap(${EXE_NAME} cap_sys_nice+ep)
