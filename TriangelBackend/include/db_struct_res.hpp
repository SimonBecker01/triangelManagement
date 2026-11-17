#pragma once

#include <string>
#include <cstdint>
#include <optional>
#include <vector>

namespace db::resolved {

struct User {
    uint64_t id = 0;
    std::string login;
    std::string lastName;
    std::string firstName;
    std::string email;
    std::string salt;
    std::string hash;
    std::string role;
};

struct Klient {
    uint64_t id = 0;
    std::string lastName;
    std::string firstName;
};

struct Betreuung {
    uint64_t id = 0;
    std::string betreuerName;
    std::string klientName;
    std::string gueltigVon;
    std::string gueltigBis;
    uint64_t stundenlohn = 0;
    uint64_t wochenstunden = 0;
};

struct Dokument {
    uint64_t id = 0;
    std::string name;
    std::string datei;
    std::string klientName;
    uint64_t gruppeId = 0;
    std::string gruppeName;
    std::vector<uint64_t> kategorieId;
    std::vector<std::string> kategorieName;
    std::string authorName;
    std::optional<std::string> vorlageName;
};

struct RolePermissions {
    std::string roleName;
    std::vector<std::string> allowedGruppen;
    std::vector<std::string> allowedKategorien;
};

struct Zeiterfassung {
    uint64_t id = 0;
    uint64_t betreuungId = 0;
    std::string betreuerName;
    std::string klientName;
    std::string taetigkeitName;
    bool istAbrechenbar = false;
    std::string von;
    std::string bis;
    std::string beschreibung;
};

} // namespace db::resolved
