#pragma once

#include <cstdint>
#include <optional>
#include <string>

namespace triangel::auth {

struct Principal {
    std::int64_t user_id;
    std::string login;
    std::int64_t expires_at;
};

// HS256 JWT issuer/verifier. The signing key must be supplied out-of-band,
// never committed to the repository or sent to clients.
class JwtManager {
public:
    JwtManager(std::string signing_key, std::string issuer, std::string audience,
               std::int64_t lifetime_seconds);

    std::string issue(std::int64_t user_id, const std::string& login) const;
    std::optional<Principal> verify(const std::string& token) const;

private:
    std::string signing_key_;
    std::string issuer_;
    std::string audience_;
    std::int64_t lifetime_seconds_;
};

} // namespace triangel::auth
