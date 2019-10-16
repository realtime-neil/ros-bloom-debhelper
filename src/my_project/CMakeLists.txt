cmake_minimum_required(VERSION 3.0.2)
project(my_project)

# dpkg assumes multiarch and cmake supports it:
# https://wiki.debian.org/Multiarch/Implementation#Dynamic_debian.2F.2A_files
# https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 11)

add_compile_options(-Wall -Wextra -Werror -fPIC)

find_package(catkin REQUIRED COMPONENTS roscpp)

# https://github.com/ros/cmake_modules
find_package(cmake_modules REQUIRED)

find_package(Boost REQUIRED COMPONENTS program_options)

catkin_package(
  CATKIN_DEPENDS roscpp
  DEPENDS Boost
)

###########
## Build ##
###########

# because ROS_DISTRO is an env var, not (yet) a cmake var
if ("" STREQUAL "$ENV{ROS_DISTRO}")
  message(FATAL_ERROR "undefined env var ROS_DISTRO")
endif()
set(ROS_DISTRO "$ENV{ROS_DISTRO}")

# because it's handy to have the debian package name
string(REPLACE "_" "-" PACKAGE_NAME "ros-${ROS_DISTRO}-${PROJECT_NAME}")

# because catkin should do this, but doesn't
set(PROJECT_VERSION ${${PROJECT_NAME}_VERSION})

if (FALSE)
  # underscores in an executable basename look weird...
  string(REPLACE "_" "-" EXE_NAME "${PROJECT_NAME}")
else()
  # ...but some people like that.
  set(EXE_NAME "${PROJECT_NAME}")
endif()

# autoconf-style config header; because config- and build-time cmake variables
# are nice to have as preprocessor definitions
configure_file(config.h.in config.h @ONLY)

include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(SYSTEM ${boost_INCLUDE_DIR} ${catkin_INCLUDE_DIRS})

add_executable(${EXE_NAME} src/main.cpp)
target_link_libraries(${EXE_NAME} LINK_PUBLIC ${Boost_LIBRARIES} ${catkin_LIBRARIES})

# project config file
configure_file(etc/project_name.conf.in etc/${PROJECT_NAME}/${PROJECT_NAME}.conf @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/etc/${PROJECT_NAME}/${PROJECT_NAME}.conf
  DESTINATION ${CMAKE_INSTALL_FULL_SYSCONFDIR}/${PROJECT_NAME})

# rsyslog filter rule - because debhelper can't do this (yet)
configure_file(etc/rsyslog.d/99-project_name.conf.in etc/rsyslog.d/99-${PROJECT_NAME}.conf @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/etc/rsyslog.d/99-${PROJECT_NAME}.conf
  DESTINATION ${CMAKE_INSTALL_FULL_SYSCONFDIR}/rsyslog.d)

# > type="nodetype"
# >     Node type. There must be a corresponding executable with the same name.
#
# -- https://wiki.ros.org/roslaunch/XML/node
#
# Yep, it has to be an executable, but that executable must be installed to the
# CATKIN_PACKAGE_BIN_DESTINATION. `roslaunch` only finds executables installed
# to the CATKIN_PACKAGE_BIN_DESTINATION and definitely NOT the
# CATKIN_GLOBAL_BIN_DESTINATION. Because of course it does.
install(TARGETS ${EXE_NAME}
  RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION})

# main launch file
# https://wiki.ros.org/catkin/CMakeLists.txt#Installing_roslaunch_Files_or_Other_Resources
configure_file(launch/main.launch.in launch/main.launch @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/launch/main.launch
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/launch)

# install (under / or /tmp/) the given kind of artifact after expanding (and
# renaming) it from the given template using the given replacement mode
function(gen_install_rootfs kind template replace_mode)
  # https://github.com/ros/catkin/pull/940
  # https://github.com/colcon/colcon-ros/pull/11
  if(CATKIN_BUILD_BINARY_PACKAGE)
    # we're making the real deal
    set(ROOTFS "/")
  else()
    # fake it to see what happens
    set(ROOTFS "/tmp/")
  endif()
  string(REGEX REPLACE "\\.in$" "" product "${template}")
  string(REPLACE "package_name" "${PACKAGE_NAME}" product "${product}")
  string(REPLACE "exe_name" "${EXE_NAME}" product "${product}")
  configure_file(${template} ${product} ${replace_mode})
  get_filename_component(parent ${product} DIRECTORY)
  install(${kind} ${CMAKE_CURRENT_BINARY_DIR}/${product}
    DESTINATION "${ROOTFS}${parent}/")
endfunction()

# executable wrapper script : usr/bin/exe_name.in -> /usr/bin/${EXE_NAME}
# https://www.freedesktop.org/software/systemd/man/file-hierarchy.html
gen_install_rootfs(PROGRAMS usr/bin/exe_name.in @ONLY)

# usr/share/icons/hicolor/scalable/apps/package_name.svg.in ->
# /usr/share/icons/hicolor/scalable/apps/${PACKAGE_NAME}.svg
# https://specifications.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html#directory_layout
gen_install_rootfs(FILES usr/share/icons/hicolor/scalable/apps/package_name.svg.in @ONLY)

# usr/share/applications/package_name.desktop.in ->
# /usr/share/applications/${PACKAGE_NAME}.desktop
# https://specifications.freedesktop.org/menu-spec/menu-spec-latest.html#locations
gen_install_rootfs(FILES usr/share/applications/package_name.desktop.in @ONLY)

# lib/systemd/system/roscore.service -> /lib/systemd/system/roscore.service
# https://www.freedesktop.org/software/systemd/man/systemd.unit.html
gen_install_rootfs(FILES lib/systemd/system/roscore.service.in @ONLY)

# this is for cmake variable hunting
if (TRUE)
  get_cmake_property(_variableNames VARIABLES)
  list (SORT _variableNames)
  foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}==${${_variableName}}")
  endforeach()
endif()
