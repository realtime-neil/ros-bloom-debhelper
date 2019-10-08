// ros-bloom-debhelper/src/my_project/src/main.cpp

#include <unistd.h>
#include <chrono>
#include <cstring>
#include <fstream>
#include <iostream>
#include <thread>

#include <boost/algorithm/string/case_conv.hpp>
#include <boost/algorithm/string/predicate.hpp>
#include <boost/algorithm/string/replace.hpp>
#include <boost/preprocessor/stringize.hpp>
#include <boost/program_options.hpp>

#include "config.h"

#if !defined(CMAKE_PROJECT_NAME)
#error "undefined CMAKE_PROJECT_NAME"
#endif

#define ENABLE_SPIT
#undef ENABLE_SPIT
#if defined(ENABLE_SPIT)
#define SPIT(X)                                                                             \
  do {                                                                                      \
    std::fprintf(stderr, "%s@%s:%d; %s: %s\n", __func__, (std::strrchr(__FILE__, '/') + 1), \
                 __LINE__, #X, _to_string((X)).c_str());                                    \
  } while (0) /**/

namespace {
std::string _to_string(std::string s) {
  return s;
}
template <typename T>
std::string _to_string(T v) {
  return std::to_string(v);
}
}
#else
#define SPIT(_) /**/
#endif

int main(int argc, char** argv) {
  std::cerr << "Hello, " << CMAKE_PROJECT_NAME << "!" << std::endl;

  std::string config_file;
  std::string runtime_dir;
  std::string state_dir;
  std::string cache_dir;
  std::string logs_dir;
  std::string config_dir;

  namespace po = ::boost::program_options;

  po::variables_map vm;

  po::options_description desc_cmdline(std::string(argv[0]) + " options");
  desc_cmdline.add_options()                                                      //
      ("help,h", "print help and return success")                                 //
      ("version", "print version and return success")                             //
      ("config-file,c", po::value<std::string>(&config_file), "config file")      //
      ("runtime-dir", po::value<std::string>(&runtime_dir), "runtime directory")  //
      ("state-dir", po::value<std::string>(&state_dir), "state directory")        //
      ("cache-dir", po::value<std::string>(&cache_dir), "cache directory")        //
      ("logs-dir", po::value<std::string>(&logs_dir), "logs directory")           //
      ("config-dir", po::value<std::string>(&config_dir), "config directory")     //
      ;

  po::options_description desc_envconf("Environment and config file options");
  desc_envconf.add_options()                                                      //
      ("runtime_dir", po::value<std::string>(&runtime_dir), "runtime directory")  //
      ("state_dir", po::value<std::string>(&state_dir), "state directory")        //
      ("cache_dir", po::value<std::string>(&cache_dir), "cache directory")        //
      ("logs_dir", po::value<std::string>(&logs_dir), "logs directory")           //
      ("config_dir", po::value<std::string>(&config_dir), "config directory")     //
      ;

  po::store(po::parse_command_line(argc, argv, desc_cmdline), vm);
  po::notify(vm);
  if (vm.count("help")) {
    std::cout << desc_cmdline << std::endl;
    return EXIT_SUCCESS;
  }

#define SPIT_OPTION(STRLIT, VAR)                          \
  do {                                                    \
    if (vm.count((STRLIT))) {                             \
      std::cerr << (STRLIT) << "=" << (VAR) << std::endl; \
    }                                                     \
  } while (0) /**/

  std::cerr << "after parsing command line:" << std::endl;
  SPIT_OPTION("config-file", config_file);
  SPIT_OPTION("runtime-dir", runtime_dir);
  SPIT_OPTION("state-dir", state_dir);
  SPIT_OPTION("cache-dir", cache_dir);
  SPIT_OPTION("logs-dir", logs_dir);
  SPIT_OPTION("config-dir", config_dir);

  std::cerr << "parsing environment..." << std::endl;
  po::store(po::parse_environment(desc_envconf,
                                  boost::to_upper_copy(std::string(CMAKE_PROJECT_NAME "_"))),
            vm);
  po::notify(vm);
  std::cerr << "parsed environment:" << std::endl;
  SPIT_OPTION("runtime_dir", runtime_dir);
  SPIT_OPTION("state_dir", state_dir);
  SPIT_OPTION("cache_dir", cache_dir);
  SPIT_OPTION("logs_dir", logs_dir);
  SPIT_OPTION("config_dir", config_dir);

  if (vm.count("config-file")) {
    SPIT(config_file);
    std::ifstream ifs(config_file);
    if (!ifs) {
      std::cerr << "cannot open config file: " << config_file << std::endl;
      return EXIT_FAILURE;
    }
    std::cerr << "parsing config file \"" << config_file << "\"..." << std::endl;
    po::store(parse_config_file(ifs, desc_envconf), vm);
    po::notify(vm);
    std::cerr << "parsed config file \"" << config_file << "\":" << std::endl;
    SPIT_OPTION("runtime_dir", runtime_dir);
    SPIT_OPTION("state_dir", state_dir);
    SPIT_OPTION("cache_dir", cache_dir);
    SPIT_OPTION("logs_dir", logs_dir);
    SPIT_OPTION("config_dir", config_dir);
  }

  // todo: go looking for config files

  // todo: use defaults

  int res = -1;
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
