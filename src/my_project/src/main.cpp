// ros-bloom-debhelper/src/my_project/src/main.cpp

#include <unistd.h>
#include <chrono>
#include <cstring>
#include <fstream>
#include <iostream>
#include <thread>

#include <boost/algorithm/string.hpp>
#include <boost/preprocessor/stringize.hpp>
#include <boost/program_options.hpp>

#include "config.h"

#if !defined(CMAKE_PROJECT_NAME)
#error "undefined CMAKE_PROJECT_NAME"
#endif

#if !defined(CMAKE_INSTALL_FULL_LOCALSTATEDIR)
#error "undefined CMAKE_INSTALL_FULL_LOCALSTATEDIR"
#endif

#if !defined(CMAKE_INSTALL_FULL_SYSCONFDIR)
#error "undefined CMAKE_INSTALL_FULL_SYSCONFDIR"
#endif

int main(int argc, char** argv) {
  std::cerr << "Hello, " << CMAKE_PROJECT_NAME << "!" << std::endl;

  std::string config_file;

  // initialize defaults
  std::string runtime_dir = "" CMAKE_INSTALL_FULL_LOCALSTATEDIR "/run/" CMAKE_PROJECT_NAME;  //
  std::string state_dir = CMAKE_INSTALL_FULL_LOCALSTATEDIR "/lib/" CMAKE_PROJECT_NAME;       //
  std::string logs_dir = CMAKE_INSTALL_FULL_LOCALSTATEDIR "/log/" CMAKE_PROJECT_NAME;        //
  std::string cache_dir = CMAKE_INSTALL_FULL_LOCALSTATEDIR "/cache/" CMAKE_PROJECT_NAME;     //
  std::string config_dir = CMAKE_INSTALL_FULL_SYSCONFDIR "/" CMAKE_PROJECT_NAME;             //

  {
    ///////////////////////////
    // PROGRAM OPTIONS BEGIN //
    ///////////////////////////
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

    po::options_description desc_envconf("environment and config file options");
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
#define SPIT_OPTION(STRLIT, VAR)                                            \
  do {                                                                      \
    if (vm.count((STRLIT))) {                                               \
      std::cerr << "  " << (STRLIT) << "=\"" << (VAR) << "\"" << std::endl; \
    }                                                                       \
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
    } else {
      // no --config-file
      auto exists = [](std::string const& path) {
        std::ifstream ifs(path);
        return ifs.good();
      };

      // https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html#variables
      auto find_config_file = [=]() {
        char* gotenv = nullptr;
        std::string res;
        if ((gotenv = std::getenv("XDG_CONFIG_HOME"))) {
          if (exists((res =                      //
                      std::string(gotenv) + "/"  //
                      CMAKE_PROJECT_NAME "/" CMAKE_PROJECT_NAME ".conf"))) {
            return res;
          }
        }
        if ((gotenv = std::getenv("HOME"))) {
          if (exists((res =                              //
                      std::string(gotenv) + "/.config/"  //
                      CMAKE_PROJECT_NAME "/" CMAKE_PROJECT_NAME ".conf"))) {
            return res;
          }
        }
        if ((gotenv = std::getenv("XDG_CONFIG_DIRS"))) {
          std::string const xdg_config_dirs(gotenv);
          std::vector<std::string> splat;
          boost::split(splat, xdg_config_dirs, boost::is_any_of(":"));
          for (std::string each : splat) {
            if (exists((res = each + "/" CMAKE_PROJECT_NAME "/" CMAKE_PROJECT_NAME ".conf"))) {
              return res;
            }
          }
        }
        // I'm not going to do the following because it's too weird:
        //
        // > If $XDG_CONFIG_DIRS is either not set or empty, a value equal to
        // > /etc/xdg should be used.
        //
        // --
        // https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html#variables

        if (exists((res = "/etc/" CMAKE_PROJECT_NAME "/" CMAKE_PROJECT_NAME ".conf"))) {
          return res;
        }
        // failed to find config file
        return (res = "");
      };

      config_file = find_config_file();
      if (!config_file.empty()) {
        // config file found
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
#undef SPIT_OPTION
      } else {
        // no config file found
        // print defaults
        std::cerr                                                       //
            << "using defaults:" << std::endl                           //
            << "  runtime_dir: \"" << runtime_dir << "\"" << std::endl  //
            << "  state_dir: \"" << state_dir << "\"" << std::endl      //
            << "  cache_dir: \"" << cache_dir << "\"" << std::endl      //
            << "  logs_dir: \"" << logs_dir << "\"" << std::endl        //
            << "  config_dir: \"" << config_dir << "\"" << std::endl    //
            ;
      }
      // config file treatment done
    }
    /////////////////////////
    // PROGRAM OPTIONS END //
    /////////////////////////
  }

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
