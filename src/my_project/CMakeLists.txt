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

find_package(Boost REQUIRED COMPONENTS program_options)

catkin_package(
  CATKIN_DEPENDS
  DEPENDS
    Boost
)

# because ROS_DISTRO is an env var, not (yet) a cmake var
if ("" STREQUAL "$ENV{ROS_DISTRO}")
  message(FATAL_ERROR "undefined env var ROS_DISTRO")
endif()
set(ROS_DISTRO "$ENV{ROS_DISTRO}")

# because it's handy to have the debian package name
string(REPLACE "_" "-" PACKAGE_NAME "ros-${ROS_DISTRO}-${PROJECT_NAME}")

# autoconf-style config header; because config- and build-time cmake variables
# are nice to have as preprocessor definitions
configure_file(config.h.in config.h @ONLY)

include_directories(
  # > A relative path is treated with respect to the value of
  # > CMAKE_CURRENT_BINARY_DIR. If the path names an existing directory the
  # > output file is placed in that directory with the same file name as the
  # > input file.
  #
  # -- https://cmake.org/cmake/help/latest/command/configure_file.html
  ${CMAKE_CURRENT_BINARY_DIR}
)

include_directories(SYSTEM ${boost_INCLUDE_DIR})

# because underscores in an executable basename look weird
string(REPLACE "_" "-" EXE_NAME "${PROJECT_NAME}")
add_executable(${EXE_NAME} src/main.cpp)
target_link_libraries(${EXE_NAME} LINK_PUBLIC ${Boost_LIBRARIES})

# project config file
configure_file(
  etc/slug.conf.in
  etc/${PROJECT_NAME}/${PROJECT_NAME}.conf
  @ONLY
)
install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/etc/${PROJECT_NAME}/${PROJECT_NAME}.conf
  DESTINATION ${CMAKE_INSTALL_FULL_SYSCONFDIR}/${PROJECT_NAME}
)

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

# this is for cmake variable hunting
if (TRUE)
  get_cmake_property(_variableNames VARIABLES)
  list (SORT _variableNames)
  foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}==${${_variableName}}")
  endforeach()
endif()
