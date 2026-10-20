#include "mailer.hpp"

#include <algorithm>
#include <atomic>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <curl/curl.h>
#include <fstream>
#include <sstream>
#include "utils.hpp"

namespace mailer {

constexpr char kResetSubject[] = "Triangel Managementsystem Passwort";
constexpr char kReminderSubject[] = "Triangel Managementsystem Erinnerung";

constexpr char kCodePlaceholder[] = "{code}";
constexpr char kResetTemplate[] = "Ihr Account wurde neu erstellt oder sein Passwort zurueckgesetzt. Das neue Passwort ist : {code}";
constexpr char kReminderBody[] =
    "Es wurden fuer diesen Monat bisher keine Arbeitszeiten eingetragen. Bitte pruefen sie dies auf Korrektheit.";
// ================================================================

constexpr long kTimeoutSeconds = 30;

namespace {

struct Upload {
    const char* data;
    size_t len;
    size_t pos = 0;
};

size_t payloadRead(char* ptr, size_t size, size_t nmemb, void* userp) {
    Upload* up = static_cast<Upload*>(userp);
    const size_t cap = size * nmemb;
    if (up->pos >= up->len || cap == 0) return 0;
    const size_t n = std::min(up->len - up->pos, cap);
    memcpy(ptr, up->data + up->pos, n);
    up->pos += n;
    return n;
}

// `to` is the only external input, so this is the one check we keep:
// must look like an address and must not contain CR/LF (header injection).
bool validAddr(const std::string& s) {
    if (s.empty()) return false;
    if (s.find('\r') != std::string::npos || s.find('\n') != std::string::npos)
        return false;
    const auto at = s.find('@');
    return at != std::string::npos && at > 0 && at + 1 < s.size();
}

std::string formatDate() {
    char buf[64];
    std::time_t now = std::time(nullptr);
    std::tm tm{};
    gmtime_r(&now, &tm);
    strftime(buf, sizeof(buf), "%a, %d %b %Y %H:%M:%S +0000", &tm);
    return buf;
}

std::string buildPayload(const std::string& host,
                         const std::string& from,
                         const std::string& to,
                         const std::string& subject,
                         const std::string& body) {
    static std::atomic<unsigned long> counter{0};
    // Bodies are LF-terminated constants; SMTP wants CRLF.
    std::string clean = body;
    while (!clean.empty() && (clean.back() == '\n' || clean.back() == '\r'))
        clean.pop_back();

    std::ostringstream oss;
    oss << "Date: " << formatDate() << "\r\n";
    oss << "To: <" << to << ">\r\n";
    oss << "From: <" << from << ">\r\n";
    oss << "Message-ID: <" << std::time(nullptr) << "." << counter++ << "@" << host
        << ">\r\n";
    oss << "Subject: " << subject << "\r\n";
    oss << "MIME-Version: 1.0\r\n";
    oss << "Content-Type: text/plain; charset=UTF-8\r\n";
    oss << "Content-Transfer-Encoding: 8bit\r\n";
    oss << "\r\n";
    oss << clean << "\r\n";
    return oss.str();
}

bool sendPayload(const SmtpConfig& config,
                 const std::string& to,
                 const std::string& subject,
                 const std::string& body,
                 std::string* error_out) {
    auto fail = [&](const std::string& msg) {
        if (error_out) *error_out = msg;
        return false;
    };

    if (config.username.empty() || config.password.empty())
        return fail("Missing SMTP credentials.");
    if (!validAddr(to)) return fail("Invalid recipient address: '" + to + "'.");
    if (!validAddr(config.username)) return fail("Invalid sender address: '" + config.username + "'.");

    CURL* curl = curl_easy_init();
    if (!curl) return fail("curl_easy_init() failed.");

    const std::string url = std::string(config.implicit_tls ? "smtps://" : "smtp://") +
                            config.host + ":" + std::to_string(config.port);
    const std::string mailFrom = "<" + config.username + ">";
    const std::string rcptTo = "<" + to + ">";
    const std::string payload = buildPayload(config.host, config.username, to, subject, body);

    struct curl_slist* recipients = curl_slist_append(nullptr, rcptTo.c_str());
    Upload up{payload.data(), payload.size()};
    char errbuf[CURL_ERROR_SIZE]{};

    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_PORT, (long)config.port);
    curl_easy_setopt(curl, CURLOPT_USERNAME, config.username.c_str());
    curl_easy_setopt(curl, CURLOPT_PASSWORD, config.password.c_str());
    curl_easy_setopt(curl, CURLOPT_MAIL_FROM, mailFrom.c_str());
    curl_easy_setopt(curl, CURLOPT_MAIL_RCPT, recipients);
    curl_easy_setopt(curl, CURLOPT_READFUNCTION, payloadRead);
    curl_easy_setopt(curl, CURLOPT_READDATA, &up);
    curl_easy_setopt(curl, CURLOPT_UPLOAD, 1L);
    curl_easy_setopt(curl, CURLOPT_INFILESIZE_LARGE, (curl_off_t)payload.size());
    curl_easy_setopt(curl, CURLOPT_USE_SSL, (long)CURLUSESSL_ALL);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);
    curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, kTimeoutSeconds);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, kTimeoutSeconds + 30);
    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
    //curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);
    curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, errbuf);

    const CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK && error_out) {
        *error_out = "Send via " + url + " as '" + config.username + "' failed: " +
                     (errbuf[0] ? errbuf : curl_easy_strerror(res));
                     std::cerr << "Send via " + url + " as '" + config.username + "' failed: " +
                     (errbuf[0] ? errbuf : curl_easy_strerror(res)) << std::endl;
    }

    curl_slist_free_all(recipients);
    curl_easy_cleanup(curl);
    return res == CURLE_OK;
}

}  // namespace

void init() { curl_global_init(CURL_GLOBAL_DEFAULT); }
void cleanup() { curl_global_cleanup(); }

bool SmtpConfig::load(SmtpConfig& out, std::string* error) {
    auto fail = [&](const std::string& msg) {
        if (error) *error = msg;
        return false;
    };


    SmtpConfig cfg;
    cfg.username = utils::load_credential("smtp_usr");
    cfg.password = utils::load_credential("smtp_cred");
    const std::string host;// = utils::load_credential("smtp_host");
    if (!host.empty()) cfg.host = host;
    const std::string port;// = utils::load_credential("smtp_port");
    if (!port.empty()) {
        try {
            cfg.port = std::stoi(port);
        } catch (...) {
            return fail("Invalid smtp_port: '" + port + "'.");
        }
    }
    cfg.implicit_tls = (cfg.port == 465);

    if (cfg.username.empty() || cfg.password.empty())
        return fail("Missing credentials: need smtp_user + smtp_pass "
                    "(systemd credentials).");
    out = cfg;
    return true;
}

bool sendPasswordReset(const SmtpConfig& config,
                       const std::string& to,
                       const std::string& code,
                       std::string* error_out) {
    if (code.empty() || code.find('\r') != std::string::npos ||
        code.find('\n') != std::string::npos) {
        if (error_out) *error_out = "Invalid reset code.";
        return false;
    }
    std::string body = kResetTemplate;
    body.replace(body.find(kCodePlaceholder), sizeof(kCodePlaceholder) - 1, code);
    return sendPayload(config, to, kResetSubject, body, error_out);
}

bool sendWorkReminder(const SmtpConfig& config,
                      const std::string& to,
                      std::string* error_out) {
    return sendPayload(config, to, kReminderSubject, kReminderBody, error_out);
}

}  // namespace mailer
