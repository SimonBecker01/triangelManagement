#pragma once

#include <string>
#include <cstdint>
#include <optional>
#include <vector>

namespace db::resolved {

struct User {
    uint64_t id;
    std::string login;
    std::string lastName;
    std::string firstName;
    std::string email;
    std::string salt;
    std::string hash;
    std::string role;
};

struct Klient {
    uint64_t id;
    std::string lastName;
    std::string firstName;
};

struct Betreuung {
    uint64_t id;
    std::string betreuuerName;
    std::string klientName;
    std::string vereinbarungName;
};

struct Dokument {
    uint64_t id;
    std::string name;
    std::string datei;
    std::string klientName;
    uint64_t gruppeId;
    std::string gruppeName;
    uint64_t kategorieId;
    std::string kategorieName;
    std::string authorName;
    std::optional<std::string> vorlageName;
};

struct RolePermissions {
    std::string roleName;
    std::vector<std::string> allowedGruppen;
    std::vector<std::string> allowedKategorien;
};

struct Vorlage {
    uint64_t id;
    std::string name;
    std::string datei;
};

struct Variable {
    uint64_t id;
    std::string vorlageName;
    std::string name;
};

struct VariablenWert {
    uint64_t id;
    std::string variableName;
    uint64_t dokumentId;
    std::string wert;
};

struct Zeiterfassung {
    uint64_t id;
    uint64_t betreuungId;
    std::string betreuuerName;
    std::string klientName;
    std::string taetigkeitName;
    bool istAbrechenbar;
    std::string von;
    std::string bis;
};

} // namespace db::resolved