#pragma once

#include "jwt_auth.hpp"
#include <grpcpp/grpcpp.h>
#include <optional>
#include <string_view>
#include <utility>
#include <string_view>
#include <utility>

namespace triangel::auth {
inline std::optional<Principal> authenticatedPrincipal(const grpc::ServerContext& context, const JwtManager& jwt) {
    const auto range = context.client_metadata().equal_range("authorization");
    constexpr std::string_view prefix = "Bearer ";
    for (auto it = range.first; it != range.second; ++it) {
        const std::string value(it->second.data(), it->second.length());
        if (value.compare(0, prefix.size(), prefix) == 0) return jwt.verify(value.substr(prefix.size()));
    }
    return std::nullopt;
}

inline grpc::Status requireAuthentication(const grpc::ServerContext& context, const JwtManager& jwt, Principal& principal) {
    auto verified = authenticatedPrincipal(context, jwt);
    if (!verified) return {grpc::StatusCode::UNAUTHENTICATED, "Missing, invalid, or expired Bearer token"};
    principal = std::move(*verified);
    return grpc::Status::OK;
}
} // namespace triangel::auth
