cmake_minimum_required(VERSION 3.0.2)
project(foobar)

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

add_executable(${PROJECT_NAME} src/main.cpp)

# rsyslog filter rule - because debhelper can't do this (yet)
configure_file(
  etc/rsyslog.d/99-foobar.conf.in
  etc/rsyslog.d/99-foobar.conf
  @ONLY
)
install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/etc/rsyslog.d/99-foobar.conf
  DESTINATION ${CMAKE_INSTALL_FULL_SYSCONFDIR}/rsyslog.d/
)

install(
  TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  RUNTIME DESTINATION ${CATKIN_GLOBAL_BIN_DESTINATION}
)
