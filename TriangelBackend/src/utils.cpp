#include "utils.hpp"

namespace utils {

    std::string load_credential(const std::string& name) {
        if (name.empty() || name.find("..") != std::string::npos || name.find('/') != std::string::npos) {
            throw std::invalid_argument("Invalid credential name: " + name);
        }

        const char* dir = std::getenv("CREDENTIALS_DIRECTORY");
        if (!dir || !*dir) {
            throw std::runtime_error("CREDENTIALS_DIRECTORY unset (not started by systemd?)");
        }

        std::filesystem::path p = std::filesystem::path(dir) / name;
        std::ifstream f(p, std::ios::binary);
        if (!f.is_open()) {
            throw std::runtime_error("Cannot open credential: " + p.string());
        }

        std::ostringstream ss;
        ss << f.rdbuf();
        if (f.bad()) {
            throw std::runtime_error("I/O error while reading credential: " + p.string());
        }

        std::string v = ss.str();

        // Trim trailing CR/LF characters for safety
        while (!v.empty() && (v.back() == '\n' || v.back() == '\r')) {
            v.pop_back();
        }

        if (v.empty()) {
            throw std::runtime_error("Credential file is empty: " + p.string());
        }
        return v;
    }

    std::string requiredEnv(const char* name) {
        if (!name || !*name) {
            throw std::invalid_argument("Environment variable name must not be empty");
        }
        if (const char* value = std::getenv(name); value && *value) {
            return value;
        }
        throw std::runtime_error(std::string("Required environment variable is not set: ") + name);
    }

    // [CHANGE] Added stream error verification and empty file check.
    std::string readFile(const std::string& path) {
        if (path.empty()) {
            throw std::invalid_argument("File path must not be empty");
        }
        std::ifstream file(path, std::ios::binary);
        if (!file.is_open()) {
            throw std::runtime_error("Cannot read file: " + path);
        }
        std::string contents{std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
        if (file.bad()) {
            throw std::runtime_error("I/O error while reading file: " + path);
        }
        if (contents.empty()) {
            throw std::runtime_error("File is empty: " + path);
        }
        return contents;
    }

} // namespace utils
