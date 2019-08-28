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

install(
  TARGETS ${EXE_NAME}
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  RUNTIME DESTINATION ${CATKIN_GLOBAL_BIN_DESTINATION}
)
