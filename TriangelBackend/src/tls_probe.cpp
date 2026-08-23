#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>

#include <fstream>
#include <iostream>
#include <iterator>
#include <string>

std::string readFile(const char* path) {
    std::ifstream file(path, std::ios::binary);

    return {
        std::istreambuf_iterator<char>(file),
        std::istreambuf_iterator<char>()
    };
}

int main() {
    //const std::string cert_pem = readFile("/tmp/grpc-test-cert.pem");
    //const std::string key_pem = readFile("/tmp/grpc-test-key.pem");
	const std::string cert_pem = readFile(
    "/home/allebescheuert/grpc-tls/allebescheuert-cert.pem"
);

const std::string key_pem = readFile(
    "/home/allebescheuert/grpc-tls/allebescheuert-key.pem"
);

    SSL_CTX* context = SSL_CTX_new(TLS_server_method());

    if (context == nullptr) {
        ERR_print_errors_fp(stderr);
        return 1;
    }

    BIO* cert_bio = BIO_new_mem_buf(
        cert_pem.data(),
        static_cast<int>(cert_pem.size())
    );

    // This is the same certificate parser gRPC 1.81 calls.
    X509* certificate = PEM_read_bio_X509_AUX(
        cert_bio, nullptr, nullptr, const_cast<char*>("")
    );

    if (certificate == nullptr) {
        std::cerr << "PEM_read_bio_X509_AUX failed:\n";
        ERR_print_errors_fp(stderr);
        BIO_free(cert_bio);
        SSL_CTX_free(context);
        return 1;
    }

    if (SSL_CTX_use_certificate(context, certificate) != 1) {
        std::cerr << "SSL_CTX_use_certificate failed:\n";
        ERR_print_errors_fp(stderr);
        X509_free(certificate);
        BIO_free(cert_bio);
        SSL_CTX_free(context);
        return 1;
    }

    BIO* key_bio = BIO_new_mem_buf(
        key_pem.data(),
        static_cast<int>(key_pem.size())
    );

    EVP_PKEY* key = PEM_read_bio_PrivateKey(
        key_bio, nullptr, nullptr, nullptr
    );

    if (key == nullptr || SSL_CTX_use_PrivateKey(context, key) != 1) {
        std::cerr << "Private-key loading failed:\n";
        ERR_print_errors_fp(stderr);
        if (key != nullptr) EVP_PKEY_free(key);
        BIO_free(key_bio);
        X509_free(certificate);
        BIO_free(cert_bio);
        SSL_CTX_free(context);
        return 1;
    }

    if (SSL_CTX_check_private_key(context) != 1) {
        std::cerr << "Certificate/key pair check failed:\n";
        ERR_print_errors_fp(stderr);
        return 1;
    }

    std::cout << "OpenSSL certificate and key loading succeeded.\n";

    EVP_PKEY_free(key);
    BIO_free(key_bio);
    X509_free(certificate);
    BIO_free(cert_bio);
    SSL_CTX_free(context);
    return 0;
}