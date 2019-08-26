// ros-init/src/foobar/src/main.cpp

#include <unistd.h>
#include <chrono>
#include <iostream>
#include <thread>

int main(int, char **) {
  while (true) {
    std::cerr << "Hello, foobar!" << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(5));
  }
  return EXIT_SUCCESS;
}
