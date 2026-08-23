#include "jwt_auth.hpp"

#include <openssl/crypto.h>
#include <openssl/evp.h>
#include <openssl/hmac.h>

#include <array>
#include <cstddef>
#include <cstddef>
#include <chrono>
#include <regex>
#include <stdexcept>
#include <vector>

namespace {
std::string base64UrlEncode(const unsigned char* input, std::size_t length) {
    std::string encoded(4 * ((length + 2) / 3), '\0');
    const int written = EVP_EncodeBlock(reinterpret_cast<unsigned char*>(encoded.data()), input,
                                        static_cast<int>(length));
    encoded.resize(written);
    while (!encoded.empty() && encoded.back() == '=') encoded.pop_back();
    for (char& c : encoded) { if (c == '+') c = '-'; else if (c == '/') c = '_'; }
    return encoded;
}

std::optional<std::string> base64UrlDecode(const std::string& value) {
    if (value.empty() || value.size() % 4 == 1) return std::nullopt;
    std::string b64 = value;
    for (char& c : b64) { if (c == '-') c = '+'; else if (c == '_') c = '/'; }
    b64.append((4 - b64.size() % 4) % 4, '=');
    std::vector<unsigned char> decoded(3 * b64.size() / 4);
    const int result = EVP_DecodeBlock(decoded.data(),
        reinterpret_cast<const unsigned char*>(b64.data()), static_cast<int>(b64.size()));
    if (result < 0) return std::nullopt;
    std::size_t bytes = static_cast<std::size_t>(result);
    if (!b64.empty() && b64.back() == '=') --bytes;
    if (b64.size() > 1 && b64[b64.size() - 2] == '=') --bytes;
    return std::string(reinterpret_cast<char*>(decoded.data()), bytes);
}

std::string hmacSha256(const std::string& key, const std::string& input) {
    std::array<unsigned char, EVP_MAX_MD_SIZE> digest{};
    unsigned int digest_length = 0;
    if (!HMAC(EVP_sha256(), key.data(), static_cast<int>(key.size()),
              reinterpret_cast<const unsigned char*>(input.data()), input.size(),
              digest.data(), &digest_length)) {
        throw std::runtime_error("HMAC-SHA256 failed");
    }
    return base64UrlEncode(digest.data(), digest_length);
}

// Logins are expected to be normal identifiers. Escaping still prevents malformed JSON.
std::string jsonEscape(const std::string& s) {
    std::string out;
    for (unsigned char c : s) {
        if (c == '"' || c == '\\') { out += '\\'; out += static_cast<char>(c); }
        else if (c >= 0x20) out += static_cast<char>(c);
    }
    return out;
}

std::optional<std::string> jsonString(const std::string& json, const char* name) {
    std::smatch match;
    const std::regex pattern(std::string("\\\"") + name + "\\\"\\s*:\\s*\\\"([^\\\"]*)\\\"");
    if (!std::regex_search(json, match, pattern)) return std::nullopt;
    return match[1].str();
}
std::optional<std::int64_t> jsonInt(const std::string& json, const char* name) {
    std::smatch match;
    const std::regex pattern(std::string("\\\"") + name + "\\\"\\s*:\\s*(-?[0-9]+)");
    if (!std::regex_search(json, match, pattern)) return std::nullopt;
    try { return std::stoll(match[1].str()); } catch (...) { return std::nullopt; }
}
} // namespace

namespace triangel::auth {
JwtManager::JwtManager(std::string signing_key, std::string issuer, std::string audience,
                       std::int64_t lifetime_seconds)
    : signing_key_(std::move(signing_key)), issuer_(std::move(issuer)),
      audience_(std::move(audience)), lifetime_seconds_(lifetime_seconds) {
    if (signing_key_.size() < 32) throw std::invalid_argument("JWT signing key must be at least 32 bytes");
    if (lifetime_seconds_ <= 0) throw std::invalid_argument("JWT lifetime must be positive");
}

std::string JwtManager::issue(std::int64_t user_id, const std::string& login) const {
    const auto now = std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    const std::string header = base64UrlEncode(reinterpret_cast<const unsigned char*>("{\"alg\":\"HS256\",\"typ\":\"JWT\"}"), 27);
    const std::string payload = "{\"iss\":\"" + jsonEscape(issuer_) + "\",\"aud\":\"" + jsonEscape(audience_) +
        "\",\"sub\":\"" + std::to_string(user_id) + "\",\"login\":\"" + jsonEscape(login) +
        "\",\"iat\":" + std::to_string(now) + ",\"exp\":" + std::to_string(now + lifetime_seconds_) + "}";
    const std::string encoded_payload = base64UrlEncode(reinterpret_cast<const unsigned char*>(payload.data()), payload.size());
    const std::string signing_input = header + "." + encoded_payload;
    return signing_input + "." + hmacSha256(signing_key_, signing_input);
}

std::optional<Principal> JwtManager::verify(const std::string& token) const {
    const auto first = token.find('.'); const auto second = token.find('.', first == std::string::npos ? first : first + 1);
    if (first == std::string::npos || second == std::string::npos || token.find('.', second + 1) != std::string::npos) return std::nullopt;
    const std::string signing_input = token.substr(0, second);
    const std::string supplied_signature = token.substr(second + 1);
    const std::string expected_signature = hmacSha256(signing_key_, signing_input);
    if (supplied_signature.size() != expected_signature.size() ||
        CRYPTO_memcmp(supplied_signature.data(), expected_signature.data(), expected_signature.size()) != 0) return std::nullopt;
    const auto header = base64UrlDecode(token.substr(0, first));
    const auto payload = base64UrlDecode(token.substr(first + 1, second - first - 1));
    if (!header || !payload || *header != "{\"alg\":\"HS256\",\"typ\":\"JWT\"}") return std::nullopt;
    const auto issuer = jsonString(*payload, "iss"), audience = jsonString(*payload, "aud"), subject = jsonString(*payload, "sub"), login = jsonString(*payload, "login");
    const auto expires_at = jsonInt(*payload, "exp");
    if (!issuer || !audience || !subject || !login || !expires_at || *issuer != issuer_ || *audience != audience_) return std::nullopt;
    const auto now = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::system_clock::now().time_since_epoch()).count();
    if (*expires_at <= now) return std::nullopt;
    try { return Principal{std::stoll(*subject), *login, *expires_at}; } catch (...) { return std::nullopt; }
}
} // namespace triangel::auth
