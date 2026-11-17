#pragma once

#include <string>

namespace mailer {

// Call once at program startup, cleanup() at shutdown.
void init();
void cleanup();

struct SmtpConfig {
    std::string host = "smtp.ionos.de";  // smtp.ionos.com/.fr/.es by country
    int port = 587;                      // 587 STARTTLS, or 465 implicit TLS
    bool implicit_tls = false;           // true only for port 465
    std::string username;                // full IONOS address (secret: smtp_usr)
    std::string password;                // mailbox password (secret: smtp_cred)

    // Loads config + secrets from systemd $CREDENTIALS_DIRECTORY
    // Returns true on success, false + message in error on failure.
    static bool load(SmtpConfig& out, std::string* error = nullptr);
};

bool sendPasswordReset(const SmtpConfig& config,
                       const std::string& to,
                       const std::string& code,
                       std::string* error_out = nullptr);

bool sendWorkReminder(const SmtpConfig& config,
                      const std::string& to,
                      std::string* error_out = nullptr);
                      
bool sendBetreuungReminder(const SmtpConfig& config,
                       const std::string& to,
                       const std::string& code,
                       std::string* error_out = nullptr);

}  // namespace mailer
