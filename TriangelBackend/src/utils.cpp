#include "utils.hpp"

namespace utils{


    std::string load_credential(const std::string& name) {
        const char* dir = std::getenv("CREDENTIALS_DIRECTORY");
        if (!dir)
            throw std::runtime_error("CREDENTIALS_DIRECTORY unset "
                                    "(not started by systemd?)");

        std::filesystem::path p = std::filesystem::path(dir) / name;
        std::ifstream f(p, std::ios::binary);
        if (!f)
            throw std::runtime_error("cannot open credential: " + p.string());

        std::ostringstream ss;
        ss << f.rdbuf();
        std::string v = ss.str();

        //Trim, zur Sicherheit
        while (!v.empty() && (v.back() == '\n' || v.back() == '\r'))
            v.pop_back();
        return v;
    }

        std::string requiredEnv(const char* name) {
        if (const char* value = std::getenv(name); value && *value) return value;
        throw std::runtime_error(std::string("Required environment variable is not set: ") + name);
    }
    std::string readFile(const std::string& path) {
        std::ifstream file(path, std::ios::binary);
        if (!file) throw std::runtime_error("Cannot read file: " + path);
        return {std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
    }

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

        return grpc::SslServerCredentials(options);
    }
}