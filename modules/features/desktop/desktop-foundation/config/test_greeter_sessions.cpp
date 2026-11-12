#include "greeter/greeter_sessions.h"

#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>
#include <unistd.h>
#include <vector>

void require(bool value, const char* message) {
  if (!value) throw std::runtime_error(message);
}

int main(int argc, char** argv) {
  require(argc == 3, "expected projected session path and inspect/launch mode");
  const auto sessions = greeter::discoverSessions();
  const auto index = greeter::findSessionIndex(sessions, "none+i3");
  require(index.has_value(), "none+i3 is not discoverable");
  const auto& i3 = sessions[*index];
  require(i3.name == "i3" && i3.sessionType == "x11", "wrong i3 session identity");
  require(std::count_if(sessions.begin(), sessions.end(), [](const auto& s) {
    return s.name == "i3";
  }) == 1, "duplicate i3 session");
  const std::string wrapper = std::string(argv[1]) + "/bin/noctalia-greeter-i3-session";
  require(i3.command == wrapper, "i3 bypasses the absolute wrapper");
  auto args = greeter::sessionArgv(i3);
  require(args == std::vector<std::string>{"noctalia-greeter-xsession", wrapper},
          "wrong actual Greeter launch argv");
  std::map<std::string, std::string> env;
  for (const auto& entry : greeter::sessionStartEnvironment(i3)) {
    env[entry.key] = entry.value;
  }
  require(env == std::map<std::string, std::string>{
    {"XDG_SESSION_TYPE", "x11"}, {"XDG_CURRENT_DESKTOP", "none+i3"},
    {"XDG_SESSION_DESKTOP", "none+i3"}
  }, "wrong actual Greeter PAM session environment");

  if (std::string(argv[2]) == "inspect") {
    for (const char* id : {"umbriel", "hyprland-uwsm"}) {
      const auto other = greeter::findSessionIndex(sessions, id);
      require(other.has_value(), "Wayland alternative is missing");
      require(sessions[*other].sessionType == "wayland", "wrong Wayland session type");
      require(greeter::sessionArgv(sessions[*other])[0] != "noctalia-greeter-xsession",
              "Wayland session was wrapped as X11");
    }
    std::cout << "Native discovery, argv and PAM environment checks passed\n";
    return 0;
  }

  require(std::string(argv[2]) == "launch", "unexpected mode");
  for (const auto& [key, value] : env) {
    require(setenv(key.c_str(), value.c_str(), 1) == 0, "cannot set mock PAM environment");
  }
  std::vector<char*> rawArgs;
  for (auto& arg : args) rawArgs.push_back(arg.data());
  rawArgs.push_back(nullptr);
  execvp(rawArgs[0], rawArgs.data());
  throw std::runtime_error("cannot execute installed X11 helper");
}
