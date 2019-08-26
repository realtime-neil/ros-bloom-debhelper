cmake_minimum_required(VERSION 3.0.2)
project(foobar)

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

install(
  TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
  RUNTIME DESTINATION ${CATKIN_GLOBAL_BIN_DESTINATION}
)
