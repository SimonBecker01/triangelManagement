#pragma once

#include <string>
#include <cstdint>
#include <optional>

namespace db::raw {

    struct User {
        uint64_t id;
        std::string login;
        std::string lastName;
        std::string firstName;
        std::string email;
        std::string salt;
        std::string hash;
        uint16_t role;
        bool forceReset;
    };

    struct Klient {
        uint64_t id;
        std::string lastName;
        std::string firstName;
    };

    struct Betreuung {
        uint64_t id;
        uint64_t betreuuer;
        uint64_t klient;
        uint64_t vereinbarung;
    };

    struct Rolle {
        uint16_t id;
        std::string rolle;
    };

    struct Dokument {
        uint64_t id;
        std::string name;
        std::string datei;
        uint64_t klient;
        uint64_t gruppe;
        std::vector<uint64_t> kategorie;
        uint64_t author;
        std::optional<uint64_t> vorlage;
    };

    struct Kategorie {
        uint64_t id;
        std::string name;
    };

    struct Gruppe {
        uint64_t id;
        std::string name;
    };

    struct RechteGruppe {
        uint64_t id;
        uint16_t role;
        uint64_t gruppe;
    };

    struct RechteKategorie {
        uint64_t id;
        uint16_t role;
        uint64_t kategorie;
    };

    struct Vorlage {
        uint64_t id;
        std::string name;
        std::string datei;
    };

    struct Variable {
        uint64_t id;
        uint64_t vorlage;
        std::string name;
    };

    struct VariablenWert {
        uint64_t id;
        uint64_t variable;
        uint64_t dokument;
        std::string wert;
    };

    struct Zeiterfassung {
        uint64_t id;
        uint64_t betreuung;
        uint64_t klient;
        uint64_t taetigkeit;
        std::string von;
        std::string bis;
        std::string beschreibung;
    };

    struct Taetigkeit {
        uint64_t id;
        std::string name;
        bool abrechenbar;
    };

} // namespace db::raw