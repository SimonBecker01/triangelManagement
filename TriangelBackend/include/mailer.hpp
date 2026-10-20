#pragma once

#include <string>

namespace mailer {

// Call once at program startup, cleanup() at shutdown.
// (Replaces the old per-mail call_once init.)
void init();
void cleanup();

struct SmtpConfig {
    std::string host = "smtp.ionos.de";  // smtp.ionos.com/.fr/.es by country
    int port = 587;                      // 587 STARTTLS, or 465 implicit TLS
    bool implicit_tls = false;           // true only for port 465
    std::string username;                // full IONOS address (secret: ionos_user)
    std::string password;                // mailbox password (secret: ionos_pass)

    // Loads config + secrets from systemd $CREDENTIALS_DIRECTORY
    // (files: ionos_user, ionos_pass, optionally ionos_host, ionos_port,
    // ionos_from), falling back to IONOS_USER / IONOS_PASS / ... env vars
    // for local testing without systemd.
    static bool load(SmtpConfig& out, std::string* error = nullptr);
};

// The only two mail kinds. Everything except `to` (and `code`) is hardcoded.
// Returns true on success, false + message in error_out on failure.
bool sendPasswordReset(const SmtpConfig& config,
                       const std::string& to,
                       const std::string& code,
                       std::string* error_out = nullptr);

bool sendWorkReminder(const SmtpConfig& config,
                      const std::string& to,
                      std::string* error_out = nullptr);

}  // namespace ionos_mailer
