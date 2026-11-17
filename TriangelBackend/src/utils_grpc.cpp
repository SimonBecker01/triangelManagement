#include "utils_grpc.hpp"
#include "utils.hpp"

namespace utils {

    std::shared_ptr<grpc::ServerCredentials> tlsCredentials() {
        const std::string certificate =
            readFile(requiredEnv("TRIANGEL_TLS_CERT"));

        const std::string private_key =
            readFile(requiredEnv("TRIANGEL_TLS_KEY"));

        grpc::SslServerCredentialsOptions options(
            GRPC_SSL_DONT_REQUEST_CLIENT_CERTIFICATE);

        grpc::SslServerCredentialsOptions::PemKeyCertPair pair;
        pair.private_key = private_key;
        pair.cert_chain = certificate;

        options.pem_key_cert_pairs.push_back(std::move(pair));

        auto creds = grpc::SslServerCredentials(options);
        if (!creds) {
            throw std::runtime_error("Failed to create gRPC SSL server credentials");
        }
        return creds;
    }

} // namespace utils
