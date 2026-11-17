#pragma once

// [CHANGE] Added #pragma once header guard to prevent multiple inclusion issues.
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <grpcpp/grpcpp.h>

namespace utils {

    std::shared_ptr<grpc::ServerCredentials> tlsCredentials();

} // namespace utils
