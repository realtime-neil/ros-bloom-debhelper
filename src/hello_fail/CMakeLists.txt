cmake_minimum_required(VERSION 3.5)
project(hello_fail)

set(CMAKE_CXX_STANDARD 11)

find_package(ament_cmake REQUIRED)
find_package(my_project REQUIRED)
find_package(rclcpp REQUIRED)

find_package(ament_cmake_gtest REQUIRED)
ament_add_gtest(${PROJECT_NAME} tests/HelloFail.cpp)
target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Werror) 

ament_export_dependencies(my_project rclcpp)
ament_package()
