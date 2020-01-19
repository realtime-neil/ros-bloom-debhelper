cmake_minimum_required(VERSION 3.0.2)
project(hello_fail)

set(CMAKE_CXX_STANDARD 11)

find_package(catkin REQUIRED COMPONENTS
  roscpp
)

catkin_package(CATKIN_DEPENDS roscpp)

catkin_add_gtest(${PROJECT_NAME} tests/HelloFail.cpp)
target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Werror) 
