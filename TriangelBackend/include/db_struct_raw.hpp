#pragma once

#include <string>
#include <cstdint>
#include <optional>
#include <vector>

namespace db::raw {

    struct User {
        uint64_t id = 0;
        std::string login;
        std::string lastName;
        std::string firstName;
        std::string email;
        std::string salt;
        std::string hash;
        uint16_t role = 0;
        bool forceReset = true;
    };

    struct Klient {
        uint64_t id = 0;
        std::string lastName;
        std::string firstName;
    };

    struct Betreuung {
        uint64_t id = 0;
        uint64_t betreuer = 0;
        uint64_t klient = 0;
        std::string gueltigVon;
        std::string gueltigBis;
        uint64_t stundensatz = 0;
        uint64_t wochenstunden = 0;
    };

    struct Rolle {
        uint16_t id = 0;
        std::string rolle;
    };

    struct Dokument {
        uint64_t id = 0;
        std::string name;
        std::string datei;
        uint64_t klient = 0;
        uint64_t gruppe = 0;
        std::vector<uint64_t> kategorie;
        uint64_t author = 0;
    };

    struct Kategorie {
        uint64_t id = 0;
        std::string name;
    };

    struct Gruppe {
        uint64_t id = 0;
        std::string name;
    };

    struct RechteGruppe {
        uint64_t id = 0;
        uint16_t role = 0;
        uint64_t gruppe = 0;
    };

    struct RechteKategorie {
        uint64_t id = 0;
        uint16_t role = 0;
        uint64_t kategorie = 0;
    };

    struct Setting {
        uint64_t id = 0;
        std::string name;
        std::string wert;
    };

    struct Zeiterfassung {
        uint64_t id = 0;
        uint64_t betreuung = 0;
        uint64_t klient = 0;
        uint64_t taetigkeit = 0;
        std::string von;
        std::string bis;
        std::string beschreibung;
    };

    struct Taetigkeit {
        uint64_t id = 0;
        std::string name;
        bool abrechenbar = false;
        bool buchbar = false;
    };

} // namespace db::raw
