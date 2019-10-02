// ros-bloom-debhelper/src/my_project/src/main.cpp

#include <unistd.h>
#include <chrono>
#include <cstring>
#include <iostream>
#include <thread>

int main(int, char **) {
  int res = -1;
  std::cerr << "Hello, my_project!" << std::endl;

  errno = 0;
  res = nice(0);
  if (errno) {
    std::cerr << "FAILURE: nice(0) == " << res << ": " << std::strerror(errno) << std::endl;
    return EXIT_FAILURE;
  }
  std::cerr << "SUCCESS: nice(0) == " << res << std::endl;

  errno = 0;
  res = nice(-5);
  if (errno) {
    std::cerr << "FAILURE: nice(-5) == " << res << ": " << std::strerror(errno) << std::endl;
    return EXIT_FAILURE;
  }
  std::cerr << "SUCCESS: nice(-5) == " << res << std::endl;

  while (true) {
    std::cerr << "sleeping for 10 seconds..." << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(10));
  }
  return EXIT_SUCCESS;
}
