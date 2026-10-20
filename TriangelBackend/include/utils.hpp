#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <grpcpp/grpcpp.h>


namespace utils {

    std::string load_credential(const std::string&);
    std::string requiredEnv(const char*);
    std::string readFile(const std::string&);

    std::shared_ptr<grpc::ServerCredentials> tlsCredentials();
}