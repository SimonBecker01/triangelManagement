#pragma once

// [CHANGE] Added #pragma once header guard to prevent multiple inclusion issues.
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <string>

namespace utils {

    std::string load_credential(const std::string& name);
    std::string requiredEnv(const char* name);
    std::string readFile(const std::string& path);

} // namespace utils
