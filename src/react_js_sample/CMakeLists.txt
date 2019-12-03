cmake_minimum_required(VERSION 3.0.2)
project(react_js_sample)

# dpkg assumes multiarch and cmake supports it:
# https://wiki.debian.org/Multiarch/Implementation#Dynamic_debian.2F.2A_files
# https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
include(GNUInstallDirs)

find_package(catkin REQUIRED COMPONENTS)

# https://github.com/ros/cmake_modules
find_package(cmake_modules REQUIRED)

catkin_package()

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

# make a ALL custom target that depends on the given path
function(always_build thepath)
  message(STATUS "always_build: ${thepath}")
  string(MAKE_C_IDENTIFIER ${thepath} thetarget)
  add_custom_target(${thetarget} ALL DEPENDS ${thepath})
endfunction()

function(npmify reladir)
  string(REGEX REPLACE "([^;]+)" "${CMAKE_CURRENT_SOURCE_DIR}/\\1" ${reladir}_paths_srcarg "${ARGN}")
  string(REGEX REPLACE "([^;]+)" "${CMAKE_CURRENT_BINARY_DIR}/\\1" ${reladir}_paths_binarg "${ARGN}")

  add_custom_target(${reladir}_target_build
    ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${reladir}/build/.touch)

  add_custom_target(${reladir}_target_nomo
    ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${reladir}/node_modules/.touch)

  add_custom_target(${reladir}_target_binarg
    ALL DEPENDS ${${reladir}_paths_binarg})

  add_custom_target(${reladir}_target_srcarg
    ALL DEPENDS ${${reladir}_paths_srcarg})

  add_dependencies(${reladir}_target_build ${reladir}_target_nomo)

  add_dependencies(${reladir}_target_nomo ${reladir}_target_binarg)

  add_dependencies(${reladir}_target_binarg ${reladir}_target_srcarg)

  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${reladir}/build/.touch
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${reladir}
    COMMAND rm -rf build
    COMMAND npm run-script build
    COMMAND touch build/.touch
  )

  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${reladir}/node_modules/.touch
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${reladir}
    COMMAND rm -rf node_modules
    COMMAND npm install
    COMMAND touch node_modules/.touch
  )

  add_custom_command(
    OUTPUT ${${reladir}_paths_binarg}
    COMMAND rm -rf ${CMAKE_CURRENT_BINARY_DIR}/${reladir}
    COMMAND tar -cf- -C ${CMAKE_CURRENT_SOURCE_DIR} ${ARGN} | tar -xf- -C ${CMAKE_CURRENT_BINARY_DIR}
  )

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${reladir}/build
    DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/${reladir}/)
endfunction()

npmify(react-js-sample
  react-js-sample/.babelrc
  react-js-sample/.npmignore
  react-js-sample/README.md
  react-js-sample/app.json
  react-js-sample/package.json
  react-js-sample/public/favicon.ico
  react-js-sample/public/index.html
  react-js-sample/server/app.js
  react-js-sample/server/index.js
  react-js-sample/server/loader.js
  react-js-sample/src/App.css
  react-js-sample/src/App.js
  react-js-sample/src/components/About/About.js
  react-js-sample/src/components/Contacts/Contacts.js
  react-js-sample/src/components/Container/Container.js
  react-js-sample/src/components/Home/Home.js
  react-js-sample/src/components/NavBar/NavBar.css
  react-js-sample/src/components/NavBar/NavBar.js
  react-js-sample/src/components/NotFound/NotFound.css
  react-js-sample/src/components/NotFound/NotFound.js
  react-js-sample/src/components/index.js
  react-js-sample/src/index.css
  react-js-sample/src/index.js
  react-js-sample/src/logo.svg
)

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
configure_file(bin/exe_name.in bin/${EXE_NAME} @ONLY)
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/bin/${EXE_NAME}
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION})

# main launch file
# https://wiki.ros.org/catkin/CMakeLists.txt#Installing_roslaunch_Files_or_Other_Resources
configure_file(launch/main.launch.in launch/main.launch @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/launch/main.launch
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/launch)

# this is for cmake variable hunting
if (TRUE)
  get_cmake_property(_variableNames VARIABLES)
  list (SORT _variableNames)
  foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}==${${_variableName}}")
  endforeach()
endif()
