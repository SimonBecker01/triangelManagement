#include "serviceimplement.hpp"
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <system_error>

namespace {
constexpr std::size_t kMaxDocumentBytes = 20u * 1024u * 1024u;

template<class Reply>
grpc::Status mutationStatus(int rc, Reply* reply) {
    if (rc == 0) return grpc::Status::OK;
    if (rc == 2) {
        reply->set_error_code("Eintrag nicht gefunden, bereits vorhanden oder noch in Verwendung.");
        return grpc::Status::OK;
    }
    if (rc == 3) return {grpc::StatusCode::PERMISSION_DENIED, "Keine Berechtigung."};
    return {grpc::StatusCode::INTERNAL, "Datenbankfehler."};
}
grpc::Status readStatus(int rc) {
    if (rc == 0) return grpc::Status::OK;
    if (rc == 2) return {grpc::StatusCode::NOT_FOUND, "Eintrag nicht gefunden."};
    if (rc == 3) return {grpc::StatusCode::PERMISSION_DENIED, "Keine Berechtigung."};
    return {grpc::StatusCode::INTERNAL, "Datenbankfehler."};
}
bool validDate(const triangel::Datum& d) {
    using namespace std::chrono;
    if (d.year() < 1000 || d.year() > 9999 || d.month() < 1 || d.month() > 12 || d.day() < 1 || d.day() > 31) return false;
    return year_month_day{year{d.year()}, month{static_cast<unsigned>(d.month())}, day{static_cast<unsigned>(d.day())}}.ok();
}
bool validTime(const triangel::Uhrzeit& t) {
    return t.hour() >= 0 && t.hour() < 24 && t.minute() >= 0 && t.minute() < 60;
}
std::string dateText(const triangel::Datum& d) {
    std::ostringstream out;
    out << std::setfill('0') << std::setw(4) << d.year() << '-' << std::setw(2) << d.month() << '-' << std::setw(2) << d.day();
    return out.str();
}
std::string dateTimeText(const triangel::Datum& d, const triangel::Uhrzeit& t) {
    std::ostringstream out;
    out << dateText(d) << '-' << std::setfill('0') << std::setw(2) << t.hour() << '-' << std::setw(2) << t.minute();
    return out.str();
}
int colorSetting(DatabaseOperator& db, const char* key, int fallback) {
    std::string value;
    if (db.getSettingsValue(key, value) != 0) return fallback;
    try {
        std::size_t used = 0;
        const int result = std::stoi(value, &used);
        return used == value.size() && result >= 0 && result <= 255 ? result : fallback;
    } catch (...) { return fallback; }
}
}



namespace services {



    AuthServiceImpl::AuthServiceImpl(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status AuthServiceImpl::Login(grpc::ServerContext* context, const triangel::LoginRequest* request, triangel::LoginReply* reply) try {
        if (request->username().empty() || request->password().empty())
            return {grpc::StatusCode::INVALID_ARGUMENT, "Nutzername und Passwort sind erforderlich."};
        std::int64_t user_id = 0; std::int32_t forceReset = 0, role = 0;
        const int rc = database_.checkUser(request->username(), request->password(), user_id, forceReset, role);
        if (rc == -1) return {grpc::StatusCode::INTERNAL, "Anmeldung derzeit nicht möglich."};
        if (rc != 0) return {grpc::StatusCode::UNAUTHENTICATED, "Nutzername oder Passwort inkorrekt."};
        std::vector<db::raw::Klient> klienten;
        if (const int clientsRc = database_.getKlienten(user_id, klienten); clientsRc != 0) return readStatus(clientsRc);
        for (const auto& k : klienten) {
            auto* item = reply->add_klienten(); item->set_id(k.id); item->set_nname(k.lastName); item->set_fname(k.firstName);
        }
        auto* dark = reply->mutable_darkbg();
        dark->set_r(colorSetting(database_, "darkBGR", 88));
        dark->set_g(colorSetting(database_, "darkBGG", 140));
        dark->set_b(colorSetting(database_, "darkBGB", 52));
        auto* light = reply->mutable_lightbg();
        light->set_r(colorSetting(database_, "lightBGR", 122));
        light->set_g(colorSetting(database_, "lightBGG", 201));
        light->set_b(colorSetting(database_, "lightBGB", 67));
        reply->set_access_token(jwt_.issue(user_id, request->username()));
        reply->set_forceresetpass(forceReset); reply->set_role(role);
        return grpc::Status::OK;
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };


    DocumentConfigService::DocumentConfigService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DocumentConfigService::GetDocumentConfig(grpc::ServerContext* context, const triangel::DocumentConfigRequest* request, triangel::DocumentConfigReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }
        std::vector<db::raw::Gruppe> groups;
        std::vector<db::raw::Kategorie> categories;
        if (auto status = readStatus(database_.getGruppen(principal.user_id, groups)); !status.ok()) return status;
        if (auto status = readStatus(database_.getKategorien(principal.user_id, categories)); !status.ok()) return status;

        for(int i = 0;i < groups.size();i++){
            triangel::IdObjekt* gruppe = reply->add_gruppen();
            gruppe->set_id(groups.at(i).id);
            gruppe->set_bezeichnung(groups.at(i).name);
        }
        
        for(int i = 0;i < categories.size();i++){
            triangel::IdObjekt* kategorie = reply->add_kategorien();
            kategorie->set_id(categories.at(i).id);
            kategorie->set_bezeichnung(categories.at(i).name);
        }

        return grpc::Status::OK;
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };


    DocumentsService::DocumentsService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DocumentsService::GetDocuments(grpc::ServerContext* context, const triangel::DocumentsRequest* request, triangel::DocumentsReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }
        std::vector<db::resolved::Dokument> documents;
        if (request->klientid() < 0) return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültige Klienten-ID."};
        if (auto status = readStatus(database_.getDokumenteAuthor(principal.user_id, request->klientid(), documents)); !status.ok()) return status;

        for(int i = 0;i < documents.size();i++){
            triangel::Dokument* dokument = reply->add_dokumente();
            dokument->set_name(documents.at(i).name);
            dokument->set_author(documents.at(i).authorName);
            dokument->set_klient(request->klientid());

            triangel::IdObjekt* gruppe = dokument->mutable_gruppe();
            gruppe->set_id(documents.at(i).gruppeId);
            gruppe->set_bezeichnung(documents.at(i).gruppeName);
            
            for(int j = 0; j <documents.at(i).kategorieId.size(); j++){
                triangel::IdObjekt* kategorie = dokument->add_kategorie();
                kategorie->set_id(documents.at(i).kategorieId.at(j));
                kategorie->set_bezeichnung(documents.at(i).kategorieName.at(j));
            }
        }

        return grpc::Status::OK;
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    DocumentService::DocumentService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DocumentService::GetDocument(grpc::ServerContext* context, const triangel::DocumentRequest* request, triangel::DocumentReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Dokument dokument;
        std::string filePath;
        dokument.name = request->dokument().name();
        dokument.gruppe = request->dokument().gruppe().id();
        for(int i = 0; i < request->dokument().kategorie().size();i++){
            dokument.kategorie.push_back(request->dokument().kategorie().at(i).id());
        }
        dokument.klient = request->dokument().klient();

        if (request->dokument().klient() < 0 || request->dokument().gruppe().id() <= 0)
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültiges Dokument."};
        if (auto status = readStatus(database_.getDokumentFile(principal.user_id, dokument, filePath)); !status.ok()) return status;

        std::ifstream documentFile(filePath, std::ios::binary);

        std::error_code error;
        std::uintmax_t size = std::filesystem::file_size(filePath, error);

        if (!documentFile || error){
        return {grpc::StatusCode::INTERNAL, "Failed to read document"};
        }

        if (size > kMaxDocumentBytes) return {grpc::StatusCode::RESOURCE_EXHAUSTED, "Dokument ist zu groß."};
        std::string documentData;
        documentData.resize(static_cast<std::size_t>(size));

        if (!documentFile.read(documentData.data(), static_cast<std::streamsize>(size))){
            return {grpc::StatusCode::INTERNAL, "Failed to read document"};
        }

        reply->set_file(std::move(documentData));

        return grpc::Status::OK;
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    DeleteDocumentService::DeleteDocumentService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DeleteDocumentService::DeleteDocument(grpc::ServerContext* context, const triangel::DeleteDocumentRequest* request, triangel::DeleteDocumentReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()) return status;
        if (request->dokument().klient() < 0 || request->dokument().gruppe().id() <= 0)
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültiges Dokument."};
        db::raw::Dokument dokument;
        dokument.name = request->dokument().name(); dokument.gruppe = request->dokument().gruppe().id(); dokument.klient = request->dokument().klient();
        std::string path;
        if (auto status = readStatus(database_.deleteDokumentFile(principal.user_id, dokument, path)); !status.ok()) return status;
        std::error_code error;
        std::filesystem::remove(path, error);
        if (error) {
            std::cerr << "Document metadata deleted, but file cleanup failed: " << error.message() << std::endl;
            return {grpc::StatusCode::INTERNAL, "Dokumentdaten entfernt, Datei konnte nicht gelöscht werden. Bitte Administrator informieren."};
        }
        return grpc::Status::OK;
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };
    
    SendDocumentService::SendDocumentService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SendDocumentService::SendDocument(grpc::ServerContext* context, const triangel::SendDocumentRequest* request, triangel::SendDocumentReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()) return status;
        if (request->dokument().klient() < 0 || request->dokument().gruppe().id() <= 0 || request->dokument().name().empty() || request->file().empty())
            return {grpc::StatusCode::INVALID_ARGUMENT, "Name, Gruppe und eine nicht leere Datei sind erforderlich."};
        if (request->file().size() > kMaxDocumentBytes) return {grpc::StatusCode::RESOURCE_EXHAUSTED, "Dokument ist zu groß (maximal 20 MiB)."};
        db::raw::Dokument dokument;
        dokument.name = request->dokument().name(); dokument.gruppe = request->dokument().gruppe().id(); dokument.klient = request->dokument().klient();
        for (const auto& category : request->dokument().kategorie()) {
            if (category.id() <= 0) return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültige Kategorie."};
            dokument.kategorie.push_back(category.id());
        }
        std::string path;
        const int rc = database_.setNewDokumentFile(principal.user_id, dokument, path);
        if (rc == 2) { reply->set_error_code("Dokument existiert bereits oder Auswahl ist nicht zulässig."); return grpc::Status::OK; }
        if (rc != 0 || path.empty()) return {grpc::StatusCode::INTERNAL, "Dokument konnte nicht angelegt werden."};
        // Database and filesystem are separate systems. Compensate a failed file
        // write by removing the inserted row and any partial file; log if cleanup fails.
        std::error_code error;
        std::filesystem::create_directories(std::filesystem::path(path).parent_path(), error);
        bool written = false;
        if (!error) {
            std::ofstream file(path, std::ios::binary | std::ios::trunc);
            if (file) {
                file.write(request->file().data(), static_cast<std::streamsize>(request->file().size()));
                file.close();
                written = !file.fail();
            }
        }
        if (!written) {
            std::error_code ignored; std::filesystem::remove(path, ignored);
            std::string rollbackPath;
            if (database_.deleteDokumentFile(principal.user_id, dokument, rollbackPath) != 0)
                std::cerr << "Unable to clean up document metadata after a failed write" << std::endl;
            return {grpc::StatusCode::INTERNAL, "Datei konnte nicht gespeichert werden."};
        }
        return grpc::Status::OK;
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };


    TaetigkeitService::TaetigkeitService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status TaetigkeitService::Taetigkeit(grpc::ServerContext* context, const triangel::TaetigkeitRequest* request, triangel::TaetigkeitReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }
        std::vector<db::raw::Taetigkeit> taetigkeiten;
        if (auto status = readStatus(database_.getTaetigkeiten(principal.user_id, taetigkeiten)); !status.ok()) return status;

        for(int i = 0;i < taetigkeiten.size();i++){
            triangel::Taetigkeit* taetigkeit = reply->add_taetigkeiten();
            taetigkeit->set_id(taetigkeiten.at(i).id);
            taetigkeit->set_bezeichnung(taetigkeiten.at(i).name);
            taetigkeit->set_abrechenbar(taetigkeiten.at(i).abrechenbar);
            taetigkeit->set_buchbar(taetigkeiten.at(i).buchbar);
        }

        return grpc::Status::OK;
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };
    
    ZeiteintraegeService::ZeiteintraegeService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ZeiteintraegeService::Zeiteintraege(grpc::ServerContext* context, const triangel::ZeiteintraegeRequest* request, triangel::ZeiteintraegeReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        std::vector<db::raw::Zeiterfassung> zeiteintraegeVector;
        if (!validDate(request->zeiteintragdatum())) return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültiges Datum."};
        const std::string day = dateText(request->zeiteintragdatum());
        if (auto status = readStatus(database_.getZeiteintraege(principal.user_id, day + "-00-00", day + "-23-59", zeiteintraegeVector)); !status.ok()) return status;

        for(int i = 0;i < zeiteintraegeVector.size();i++){
            
            triangel::Zeiteintrag* eintrag = reply->add_zeiteintraege();

            eintrag->mutable_dayofentry()->set_year(std::stoi(zeiteintraegeVector.at(i).von.substr(0, 4)));
            eintrag->mutable_dayofentry()->set_month(std::stoi(zeiteintraegeVector.at(i).von.substr(5, 2)));
            eintrag->mutable_dayofentry()->set_day(std::stoi(zeiteintraegeVector.at(i).von.substr(8, 2)));

            eintrag->mutable_anfang()->set_hour(std::stoi(zeiteintraegeVector.at(i).von.substr(11, 2)));
            eintrag->mutable_anfang()->set_minute(std::stoi(zeiteintraegeVector.at(i).von.substr(14, 2)));

            eintrag->mutable_ende()->set_hour(std::stoi(zeiteintraegeVector.at(i).bis.substr(11, 2)));
            eintrag->mutable_ende()->set_minute(std::stoi(zeiteintraegeVector.at(i).bis.substr(14, 2)));

            eintrag->set_taetigkeitid(zeiteintraegeVector.at(i).taetigkeit);
            eintrag->set_klientid(zeiteintraegeVector.at(i).klient);
            eintrag->set_beschreibung(zeiteintraegeVector.at(i).beschreibung);
            eintrag->set_eintragid(zeiteintraegeVector.at(i).id);
        }

        return grpc::Status::OK;
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };
    
    ZeiteintragService::ZeiteintragService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ZeiteintragService::Zeiteintrag(grpc::ServerContext* context, const triangel::ZeiteintragRequest* request, triangel::ZeiteintragReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()) return status;
        const auto& entry = request->zeiteintrag();
        if (request->operation() < 1 || request->operation() > 3 || entry.klientid() <= 0 || (request->operation() != 1 && entry.eintragid() <= 0))
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültiger Eintrag oder Vorgang."};
        db::raw::Zeiterfassung raw;
        raw.id = entry.eintragid(); raw.klient = entry.klientid(); raw.taetigkeit = entry.taetigkeitid(); raw.beschreibung = entry.beschreibung();
        if (request->operation() != 3) {
            if (!validDate(entry.dayofentry()) || !validTime(entry.anfang()) || !validTime(entry.ende()) || entry.taetigkeitid() <= 0 || entry.beschreibung().size() > 255)
                return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültiges Datum, Uhrzeit oder Tätigkeit."};
            raw.von = dateTimeText(entry.dayofentry(), entry.anfang()); raw.bis = dateTimeText(entry.dayofentry(), entry.ende());
        }
        std::string message;
        int rc = request->operation() == 1 ? database_.addZeiteintrag(principal.user_id, raw, message)
               : request->operation() == 2 ? database_.changeZeiteintrag(principal.user_id, raw, message)
               : database_.deleteZeiteintrag(principal.user_id, raw);
        if (rc == 0) return grpc::Status::OK;
        if (rc == 2 || rc == 3) {
            reply->set_error_code(message.empty() ? "Eintrag oder Betreuung nicht gefunden." : message);
            return grpc::Status::OK;
        }
        return {grpc::StatusCode::INTERNAL, "Zeiteintrag konnte nicht gespeichert werden."};
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    PasswordChangeService::PasswordChangeService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status PasswordChangeService::PasswordChange(grpc::ServerContext* context, const triangel::PasswordChangeRequest* request, triangel::PasswordChangeReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()) return status;
        if (request->newpassword().empty()) return {grpc::StatusCode::INVALID_ARGUMENT, "Neues Passwort darf nicht leer sein."};
        const int rc = database_.changePass(principal.user_id, request->oldpassword(), request->newpassword());
        if (rc == 0) return grpc::Status::OK;
        if (rc == -1 || rc == 2) { reply->set_error_code("Altes Passwort ist nicht korrekt."); return grpc::Status::OK; }
        return {grpc::StatusCode::INTERNAL, "Passwort konnte nicht geändert werden."};
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    CreateUserService::CreateUserService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status CreateUserService::CreateUser(grpc::ServerContext* context, const triangel::CreateUserRequest* request, triangel::CreateUserReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        // Validate before narrowing an ID to the schema's unsigned type.
        if (request->newuser().role() <= 0 || request->newuser().role() > 65535)
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültige Rollen-ID."};

        db::raw::User newUser;
        newUser.login = request->newuser().loginname();
        newUser.email = request->newuser().email();
        newUser.firstName = request->newuser().fname();
        newUser.lastName = request->newuser().lname();
        newUser.role = request->newuser().role();

        int rc = database_.createUserByService(principal.user_id, newUser);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    GetUsersService::GetUsersService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status GetUsersService::GetUsers(grpc::ServerContext* context, const triangel::GetUsersRequest* request, triangel::GetUsersReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        std::vector<db::raw::User> userListVector;

        int rc = database_.getUsersList(principal.user_id, userListVector);


        switch (rc)
        {
        case 0:
            for(int i = 0;i < userListVector.size();i++){
            
                triangel::UserObjekt* eintrag = reply->add_userlist();

                eintrag->set_id(userListVector.at(i).id);
                eintrag->set_loginname(userListVector.at(i).login);
                eintrag->set_email(userListVector.at(i).email);
                eintrag->set_fname(userListVector.at(i).firstName);
                eintrag->set_lname(userListVector.at(i).lastName);
                eintrag->set_role(userListVector.at(i).role);

            }
            return grpc::Status::OK;
        case 3:
            return grpc::Status(grpc::StatusCode::PERMISSION_DENIED, "Unauthorized Access");
        default:
            return readStatus(rc);
        }
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };
    

    GetRolesService::GetRolesService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status GetRolesService::GetRoles(grpc::ServerContext* context, const triangel::GetRolesRequest* request, triangel::GetRolesReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        std::vector<db::raw::Rolle> roleListVector;

        int rc = database_.getRolesList(principal.user_id, roleListVector);


        switch (rc)
        {
        case 0:
            for(int i = 0;i < roleListVector.size();i++){
            
                triangel::IdObjekt* eintrag = reply->add_roleslist();

                eintrag->set_id(roleListVector.at(i).id);
                eintrag->set_bezeichnung(roleListVector.at(i).rolle);

            }
            return grpc::Status::OK;
        case 3:
            return grpc::Status(grpc::StatusCode::PERMISSION_DENIED, "Unauthorized Access");
        default:
            return readStatus(rc);
        }
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    ChangeUserService::ChangeUserService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ChangeUserService::ChangeUser(grpc::ServerContext* context, const triangel::ChangeUserRequest* request, triangel::ChangeUserReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        // Validate before narrowing an ID to the schema's unsigned type.
        if (request->changeduser().id() <= 0 || request->changeduser().role() <= 0 || request->changeduser().role() > 65535)
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültiger Nutzer oder Rollen-ID."};

        db::raw::User changedUser;
        changedUser.id = request->changeduser().id();
        changedUser.login = request->changeduser().loginname();
        changedUser.email = request->changeduser().email();
        changedUser.firstName = request->changeduser().fname();
        changedUser.lastName = request->changeduser().lname();
        changedUser.role = request->changeduser().role();
        changedUser.forceReset = request->forcereset() != 0;

        int rc = database_.changeUser(principal.user_id, changedUser);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };


    GetRechteKategorienService::GetRechteKategorienService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status GetRechteKategorienService::GetRechteKategorien(grpc::ServerContext* context, const triangel::GetRechteKategorienRequest* request, triangel::GetRechteKategorienReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        std::vector<db::raw::RechteKategorie> rk;

        int rc = database_.getRechteKategorien(principal.user_id, rk);

        switch (rc)
        {
        case 0:
            for(int i = 0;i < rk.size();i++){
            
                triangel::IdPair* eintrag = reply->add_rechtekategorien();

                eintrag->set_idfirst(rk.at(i).role);
                eintrag->set_idsecond(rk.at(i).kategorie);

            }
            return grpc::Status::OK;
        default:
            return readStatus(rc);
        }
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    GetRechteGruppeService::GetRechteGruppeService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status GetRechteGruppeService::GetRechteGruppe(grpc::ServerContext* context, const triangel::GetRechteGruppeRequest* request, triangel::GetRechteGruppeReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        std::vector<db::raw::RechteGruppe> rg;

        int rc = database_.getRechteGruppe(principal.user_id, rg);

        switch (rc)
        {
        case 0:
            for(int i = 0;i < rg.size();i++){
            
                triangel::IdPair* eintrag = reply->add_rechtegruppe();

                eintrag->set_idfirst(rg.at(i).role);
                eintrag->set_idsecond(rg.at(i).gruppe);

            }
            return grpc::Status::OK;
        default:
            return readStatus(rc);
        }
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    SetRechteService::SetRechteService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SetRechteService::SetRechte(grpc::ServerContext* context, const triangel::SetRechteRequest* request, triangel::SetRechteReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        std::vector<uint64_t> k;
        std::vector<uint64_t> g;

        for(int i = 0;i < request->kategorienid().size();i++){
            k.push_back(request->kategorienid().at(i));
        }

        for(int i = 0;i < request->gruppenid().size();i++){
            g.push_back(request->gruppenid().at(i));
        }

        int rc = database_.setRechte(principal.user_id, request->rollenid(), k, g);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    ChangeRolleService::ChangeRolleService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ChangeRolleService::ChangeRolle(grpc::ServerContext* context, const triangel::ChangeRolleRequest* request, triangel::ChangeRolleReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        // Validate before narrowing an ID to the schema's unsigned type.
        if (request->rolle().id() <= 0 || request->rolle().id() > 65535)
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültige Rollen-ID."};

        db::raw::Rolle rol;
        rol.id = request->rolle().id();
        rol.rolle = request->rolle().bezeichnung();

        int rc = database_.changeRolle(principal.user_id, rol);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    ChangeKategorieService::ChangeKategorieService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ChangeKategorieService::ChangeKategorie(grpc::ServerContext* context, const triangel::ChangeKategorieRequest* request, triangel::ChangeKategorieReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Kategorie kat;
        kat.id = request->kategorie().id();
        kat.name = request->kategorie().bezeichnung();

        int rc = database_.changeKategorie(principal.user_id, kat);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    ChangeGruppeService::ChangeGruppeService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ChangeGruppeService::ChangeGruppe(grpc::ServerContext* context, const triangel::ChangeGruppeRequest* request, triangel::ChangeGruppeReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Gruppe grup;
        grup.id = request->gruppe().id();
        grup.name = request->gruppe().bezeichnung();

        int rc = database_.changeGruppe(principal.user_id, grup);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    DeleteRolleService::DeleteRolleService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DeleteRolleService::DeleteRolle(grpc::ServerContext* context, const triangel::DeleteRolleRequest* request, triangel::DeleteRolleReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        // Validate before narrowing an ID to the schema's unsigned type.
        if (request->rolle().id() <= 0 || request->rolle().id() > 65535)
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültige Rollen-ID."};

        db::raw::Rolle rol;
        rol.id = request->rolle().id();

        int rc = database_.deleteRolle(principal.user_id, rol);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    DeleteKategorieService::DeleteKategorieService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DeleteKategorieService::DeleteKategorie(grpc::ServerContext* context, const triangel::DeleteKategorieRequest* request, triangel::DeleteKategorieReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Kategorie kat;
        kat.id = request->kategorie().id();

        int rc = database_.deleteKategorie(principal.user_id, kat);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    DeleteGruppeService::DeleteGruppeService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DeleteGruppeService::DeleteGruppe(grpc::ServerContext* context, const triangel::DeleteGruppeRequest* request, triangel::DeleteGruppeReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Gruppe grup;
        grup.id = request->gruppe().id();

        int rc = database_.deleteGruppe(principal.user_id, grup);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    SetNewRolleService::SetNewRolleService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SetNewRolleService::SetNewRolle(grpc::ServerContext* context, const triangel::SetNewRolleRequest* request, triangel::SetNewRolleReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Rolle rol;
        rol.rolle = request->rolle().bezeichnung();

        int rc = database_.setNewRolle(principal.user_id, rol);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    SetNewKategorieService::SetNewKategorieService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SetNewKategorieService::SetNewKategorie(grpc::ServerContext* context, const triangel::SetNewKategorieRequest* request, triangel::SetNewKategorieReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Kategorie kat;
        kat.name = request->kategorie().bezeichnung();

        int rc = database_.setNewKategorie(principal.user_id, kat);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    SetNewGruppeService::SetNewGruppeService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SetNewGruppeService::SetNewGruppe(grpc::ServerContext* context, const triangel::SetNewGruppeRequest* request, triangel::SetNewGruppeReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Gruppe grup;
        grup.name = request->gruppe().bezeichnung();

        int rc = database_.setNewGruppe(principal.user_id, grup);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    ChangeTaetigkeitService::ChangeTaetigkeitService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ChangeTaetigkeitService::ChangeTaetigkeit(grpc::ServerContext* context, const triangel::ChangeTaetigkeitRequest* request, triangel::ChangeTaetigkeitReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Taetigkeit taet;
        taet.id = request->taetigkeit().id();
        taet.name = request->taetigkeit().bezeichnung();
        taet.abrechenbar = request->taetigkeit().abrechenbar();
        taet.buchbar = request->taetigkeit().buchbar();

        int rc = database_.changeTaetigkeit(principal.user_id, taet);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    DeleteTaetigkeitService::DeleteTaetigkeitService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DeleteTaetigkeitService::DeleteTaetigkeit(grpc::ServerContext* context, const triangel::DeleteTaetigkeitRequest* request, triangel::DeleteTaetigkeitReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Taetigkeit taet;
        taet.id = request->taetigkeitid();


        int rc = database_.deleteTaetigkeit(principal.user_id, taet);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    SetNewTaetigkeitService::SetNewTaetigkeitService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SetNewTaetigkeitService::SetNewTaetigkeit(grpc::ServerContext* context, const triangel::SetNewTaetigkeitRequest* request, triangel::SetNewTaetigkeitReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Taetigkeit taet;
        taet.name = request->taetigkeit().bezeichnung();
        taet.abrechenbar = request->taetigkeit().abrechenbar();
        taet.buchbar = request->taetigkeit().buchbar();


        int rc = database_.setNewTaetigkeit(principal.user_id, taet);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    GetBetreuungenService::GetBetreuungenService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status GetBetreuungenService::GetBetreuungen(grpc::ServerContext* context, const triangel::GetBetreuungenRequest* request, triangel::GetBetreuungenReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        std::vector<db::raw::Betreuung> betreuungen;

        int rc = database_.getBetreuungen(principal.user_id, request->aktiv(), betreuungen);

        switch (rc)
        {
        case 0:
            for(int i = 0;i < betreuungen.size();i++){
            
                triangel::Betreuung* eintrag = reply->add_betreuungen();

                eintrag->set_id(betreuungen.at(i).id);
                eintrag->set_betreuerid(betreuungen.at(i).betreuer);
                eintrag->set_klientid(betreuungen.at(i).klient);
                eintrag->set_stundensatz(betreuungen.at(i).stundensatz);
                eintrag->set_wochenstunden(betreuungen.at(i).wochenstunden);


                eintrag->mutable_gueltigvon()->set_year(std::stoi(betreuungen.at(i).gueltigVon.substr(0, 4)));
                eintrag->mutable_gueltigvon()->set_month(std::stoi(betreuungen.at(i).gueltigVon.substr(5, 2)));
                eintrag->mutable_gueltigvon()->set_day(std::stoi(betreuungen.at(i).gueltigVon.substr(8, 2)));

                eintrag->mutable_gueltigbis()->set_year(std::stoi(betreuungen.at(i).gueltigBis.substr(0, 4)));
                eintrag->mutable_gueltigbis()->set_month(std::stoi(betreuungen.at(i).gueltigBis.substr(5, 2)));
                eintrag->mutable_gueltigbis()->set_day(std::stoi(betreuungen.at(i).gueltigBis.substr(8, 2)));

            }
            return grpc::Status::OK;
        default:
            return readStatus(rc);
        }
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    EndBetreuungService::EndBetreuungService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status EndBetreuungService::EndBetreuung(grpc::ServerContext* context, const triangel::EndBetreuungRequest* request, triangel::EndBetreuungReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }


        int rc = database_.endBetreuung(principal.user_id, request->betreuungid());
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    SetNewBetreuungService::SetNewBetreuungService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SetNewBetreuungService::SetNewBetreuung(grpc::ServerContext* context, const triangel::SetNewBetreuungRequest* request, triangel::SetNewBetreuungReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        if (request->betreuung().betreuerid() <= 0 || request->betreuung().klientid() <= 0 ||
            request->betreuung().wochenstunden() < 0 || request->betreuung().stundensatz() < 0 ||
            !validDate(request->betreuung().gueltigvon()) || !validDate(request->betreuung().gueltigbis()))
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültige Betreuung."};
        db::raw::Betreuung betreuung;

        betreuung.betreuer = request->betreuung().betreuerid();
        betreuung.klient = request->betreuung().klientid();
        betreuung.gueltigVon = dateText(request->betreuung().gueltigvon());
        betreuung.gueltigBis = dateText(request->betreuung().gueltigbis());
        betreuung.stundensatz = request->betreuung().stundensatz();
        betreuung.wochenstunden = request->betreuung().wochenstunden();

        int rc = database_.setNewBetreuung(principal.user_id, betreuung);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    AuswertungBetreuungService::AuswertungBetreuungService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status AuswertungBetreuungService::AuswertungBetreuung(grpc::ServerContext* context, const triangel::AuswertungBetreuungRequest* request, triangel::AuswertungReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        // Reports use only year and month; reject impossible selectors up front.
        if (request->betreuung() <= 0 || request->monat().year() < 1000 || request->monat().year() > 9999 ||
            request->monat().month() < 1 || request->monat().month() > 12)
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültige Auswertungsauswahl."};
        std::vector<db::resolved::Zeiterfassung> eintraege;

        int rc = database_.getAuswertungBetreuung(principal.user_id, request->betreuung(), std::to_string(request->monat().year()) + "-" + std::to_string(request->monat().month()) + "-01", request->abrechenbar(), eintraege);

        switch (rc)
        {
        case 0:
            for(int i = 0;i < eintraege.size();i++){
            
                triangel::Auswertung* eintrag = reply->add_auswertung();

                
                eintrag->mutable_dayofentry()->set_year(std::stoi(eintraege.at(i).von.substr(0, 4)));
                eintrag->mutable_dayofentry()->set_month(std::stoi(eintraege.at(i).von.substr(5, 2)));
                eintrag->mutable_dayofentry()->set_day(std::stoi(eintraege.at(i).von.substr(8, 2)));

                eintrag->mutable_anfang()->set_hour(std::stoi(eintraege.at(i).von.substr(11, 2)));
                eintrag->mutable_anfang()->set_minute(std::stoi(eintraege.at(i).von.substr(14, 2)));

                eintrag->mutable_ende()->set_hour(std::stoi(eintraege.at(i).bis.substr(11, 2)));
                eintrag->mutable_ende()->set_minute(std::stoi(eintraege.at(i).bis.substr(14, 2)));

                eintrag->set_taetigkeit(eintraege.at(i).taetigkeitName);
                eintrag->set_betreuer(eintraege.at(i).betreuerName);
                eintrag->set_klient(eintraege.at(i).klientName);
                eintrag->set_beschreibung(eintraege.at(i).beschreibung);
                eintrag->set_abrechenbar(eintraege.at(i).istAbrechenbar);

            }
            return grpc::Status::OK;
        default:
            return readStatus(rc);
        }
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    AuswertungBetreuerService::AuswertungBetreuerService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status AuswertungBetreuerService::AuswertungBetreuer(grpc::ServerContext* context, const triangel::AuswertungBetreuerRequest* request, triangel::AuswertungReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        // Reports use only year and month; reject impossible selectors up front.
        if (request->betreuer() <= 0 || request->monat().year() < 1000 || request->monat().year() > 9999 ||
            request->monat().month() < 1 || request->monat().month() > 12)
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültige Auswertungsauswahl."};
        std::vector<db::resolved::Zeiterfassung> eintraege;


        int rc = database_.getAuswertungBetreuer(principal.user_id, request->betreuer(), std::to_string(request->monat().year()) + "-" + std::to_string(request->monat().month()) + "-01", request->abrechenbar(), eintraege);

        switch (rc)
        {
        case 0:
            for(int i = 0;i < eintraege.size();i++){
            
                triangel::Auswertung* eintrag = reply->add_auswertung();

                
                eintrag->mutable_dayofentry()->set_year(std::stoi(eintraege.at(i).von.substr(0, 4)));
                eintrag->mutable_dayofentry()->set_month(std::stoi(eintraege.at(i).von.substr(5, 2)));
                eintrag->mutable_dayofentry()->set_day(std::stoi(eintraege.at(i).von.substr(8, 2)));

                eintrag->mutable_anfang()->set_hour(std::stoi(eintraege.at(i).von.substr(11, 2)));
                eintrag->mutable_anfang()->set_minute(std::stoi(eintraege.at(i).von.substr(14, 2)));

                eintrag->mutable_ende()->set_hour(std::stoi(eintraege.at(i).bis.substr(11, 2)));
                eintrag->mutable_ende()->set_minute(std::stoi(eintraege.at(i).bis.substr(14, 2)));

                eintrag->set_taetigkeit(eintraege.at(i).taetigkeitName);
                eintrag->set_betreuer(eintraege.at(i).betreuerName);
                eintrag->set_klient(eintraege.at(i).klientName);
                eintrag->set_beschreibung(eintraege.at(i).beschreibung);
                eintrag->set_abrechenbar(eintraege.at(i).istAbrechenbar);

            }
            return grpc::Status::OK;
        default:
            return readStatus(rc);
        }
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    AuswertungKlientService::AuswertungKlientService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status AuswertungKlientService::AuswertungKlient(grpc::ServerContext* context, const triangel::AuswertungKlientRequest* request, triangel::AuswertungReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        // Reports use only year and month; reject impossible selectors up front.
        if (request->klient() <= 0 || request->monat().year() < 1000 || request->monat().year() > 9999 ||
            request->monat().month() < 1 || request->monat().month() > 12)
            return {grpc::StatusCode::INVALID_ARGUMENT, "Ungültige Auswertungsauswahl."};
        std::vector<db::resolved::Zeiterfassung> eintraege;


        int rc = database_.getAuswertungKlient(principal.user_id, request->klient(), std::to_string(request->monat().year()) + "-" + std::to_string(request->monat().month()) + "-01", request->abrechenbar(), eintraege);

        switch (rc)
        {
        case 0:
            for(int i = 0;i < eintraege.size();i++){
            
                triangel::Auswertung* eintrag = reply->add_auswertung();

                
                eintrag->mutable_dayofentry()->set_year(std::stoi(eintraege.at(i).von.substr(0, 4)));
                eintrag->mutable_dayofentry()->set_month(std::stoi(eintraege.at(i).von.substr(5, 2)));
                eintrag->mutable_dayofentry()->set_day(std::stoi(eintraege.at(i).von.substr(8, 2)));

                eintrag->mutable_anfang()->set_hour(std::stoi(eintraege.at(i).von.substr(11, 2)));
                eintrag->mutable_anfang()->set_minute(std::stoi(eintraege.at(i).von.substr(14, 2)));

                eintrag->mutable_ende()->set_hour(std::stoi(eintraege.at(i).bis.substr(11, 2)));
                eintrag->mutable_ende()->set_minute(std::stoi(eintraege.at(i).bis.substr(14, 2)));

                eintrag->set_taetigkeit(eintraege.at(i).taetigkeitName);
                eintrag->set_betreuer(eintraege.at(i).betreuerName);
                eintrag->set_klient(eintraege.at(i).klientName);
                eintrag->set_beschreibung(eintraege.at(i).beschreibung);
                eintrag->set_abrechenbar(eintraege.at(i).istAbrechenbar);

            }
            return grpc::Status::OK;
        default:
            return readStatus(rc);
        }
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    ChangeKlientService::ChangeKlientService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ChangeKlientService::ChangeKlient(grpc::ServerContext* context, const triangel::ChangeKlientRequest* request, triangel::ChangeKlientReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Klient klient;
        klient.id = request->klient().id();
        klient.lastName = request->klient().nname();
        klient.firstName = request->klient().fname();

        int rc = database_.changeKlient(principal.user_id, klient);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    DeleteKlientService::DeleteKlientService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DeleteKlientService::DeleteKlient(grpc::ServerContext* context, const triangel::DeleteKlientRequest* request, triangel::DeleteKlientReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Klient klient;
        klient.id = request->klientid();


        int rc = database_.deleteKlient(principal.user_id, klient);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };

    SetNewKlientService::SetNewKlientService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SetNewKlientService::SetNewKlient(grpc::ServerContext* context, const triangel::SetNewKlientRequest* request, triangel::SetNewKlientReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Klient klient;
        klient.lastName = request->klient().nname();
        klient.firstName = request->klient().fname();


        int rc = database_.setNewKlient(principal.user_id, klient);
        return mutationStatus(rc, reply);
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };
    

    GetKlientenService::GetKlientenService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status GetKlientenService::GetKlienten(grpc::ServerContext* context, const triangel::GetKlientenRequest* request, triangel::GetKlientenReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        std::vector<db::raw::Klient> klientListVector;

        int rc = database_.getKlientenList(principal.user_id, klientListVector);


        switch (rc)
        {
        case 0:
            for(int i = 0;i < klientListVector.size();i++){
            
                triangel::Klient* eintrag = reply->add_klientenlist();

                eintrag->set_id(klientListVector.at(i).id);
                eintrag->set_nname(klientListVector.at(i).lastName);
                eintrag->set_fname(klientListVector.at(i).firstName);

            }
            return grpc::Status::OK;
        case 3:
            return grpc::Status(grpc::StatusCode::PERMISSION_DENIED, "Unauthorized Access");
        default:
            return readStatus(rc);
        }
    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };
    

    GetSettingsService::GetSettingsService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status GetSettingsService::GetSettings(grpc::ServerContext* context, const triangel::GetSettingsRequest* request, triangel::GetSettingsReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        for(int i = 0; i < request->names().size(); i++){
            std::string retVal;
            int rc = database_.getSettingsValue(request->names().at(i), retVal);
            switch (rc)
                {
                case 0:
                    {
                        triangel::Setting* eintrag = reply->add_settingslist();

                        eintrag->set_name(request->names().at(i));
                        eintrag->set_wert(retVal);
                    }
                    break;
                case 3:
                    return grpc::Status(grpc::StatusCode::PERMISSION_DENIED, "Unauthorized Access");
                default:
                    return readStatus(rc);
                }
        }

        return grpc::Status::OK;



    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };
    

    SetSettingsService::SetSettingsService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SetSettingsService::SetSettings(grpc::ServerContext* context, const triangel::SetSettingsRequest* request, triangel::SetSettingsReply* reply) try {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        for(int i = 0; i < request->settingslist().size(); i++){
            int rc = database_.setSettingsValue(principal.user_id, request->settingslist().at(i).name(), request->settingslist().at(i).wert());
            switch (rc)
                {
                case 4:
                    {
                        std::string* eintrag = reply->add_error_code();
                        *eintrag = std::string("Inserted");
                    }
                    break;
                case 5:
                    {
                        std::string* eintrag = reply->add_error_code();
                        *eintrag = std::string("Updated");
                    }
                    break;
                case 3:
                    return grpc::Status(grpc::StatusCode::PERMISSION_DENIED, "Unauthorized Access");
                default:
                    return readStatus(rc);
                }
        }

        return grpc::Status::OK;

    } catch (const std::exception& error) {
        std::cerr << "RPC failed: " << error.what() << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    } catch (...) {
        std::cerr << "RPC failed with an unknown exception" << std::endl;
        return {grpc::StatusCode::INTERNAL, "Interner Serverfehler."};
    };
	
}