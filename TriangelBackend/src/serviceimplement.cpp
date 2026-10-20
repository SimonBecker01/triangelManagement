#include "serviceimplement.hpp"


namespace services {



    AuthServiceImpl::AuthServiceImpl(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status AuthServiceImpl::Login(grpc::ServerContext* context, const triangel::LoginRequest* request, triangel::LoginReply* reply) {
        std::int64_t user_id = 0;
        std::int32_t forceReset = 0;
        std::int32_t role = 0;
        if (database_.checkUser(request->username(), request->password(), user_id, forceReset, role) != 0)
            return {grpc::StatusCode::UNAUTHENTICATED, "Nutzername oder Passwort inkorrekt."};
        reply->set_access_token(jwt_.issue(user_id, request->username()));
        reply->set_forceresetpass(forceReset);
        reply->set_role(role);
        std::vector<db::raw::Klient> klientenVector;
        database_.getKlienten(user_id, klientenVector);
        for(int i = 0;i < klientenVector.size();i++){
            triangel::Klient* nextKlient = reply->add_klienten();
            nextKlient->set_id(klientenVector.at(i).id);
            nextKlient->set_nname(klientenVector.at(i).lastName);
            nextKlient->set_fname(klientenVector.at(i).firstName);
        }
        std::string r, g, b;
        if(database_.getSettingsValue("darkBGR", r) != 0 || r.empty()) r = "88";
        if(database_.getSettingsValue("darkBGG", g) != 0 || g.empty()) r = "140";
        if(database_.getSettingsValue("darkBGB", b) != 0 || b.empty()) r = "52";
        triangel::Color* dbg = reply->mutable_darkbg();
        dbg->set_r(std::stoi(r));
        dbg->set_g(std::stoi(g));
        dbg->set_b(std::stoi(b));
        
        if(database_.getSettingsValue("lightBGR", r) != 0 || r.empty()) r = "122";
        if(database_.getSettingsValue("lightBGG", g) != 0 || g.empty()) r = "201";
        if(database_.getSettingsValue("lightBGB", b) != 0 || b.empty()) r = "67";
        triangel::Color* lbg = reply->mutable_lightbg();
        lbg->set_r(std::stoi(r));
        lbg->set_g(std::stoi(g));
        lbg->set_b(std::stoi(b));

        return grpc::Status::OK;
    };


    DocumentConfigService::DocumentConfigService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DocumentConfigService::GetDocumentConfig(grpc::ServerContext* context, const triangel::DocumentConfigRequest* request, triangel::DocumentConfigReply* reply) {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }
        std::vector<db::raw::Gruppe> groups;
        std::vector<db::raw::Kategorie> categories;
        database_.getGruppen(principal.user_id, groups);
        database_.getKategorien(principal.user_id, categories);

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
    };


    DocumentsService::DocumentsService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DocumentsService::GetDocuments(grpc::ServerContext* context, const triangel::DocumentsRequest* request, triangel::DocumentsReply* reply) {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }
        std::vector<db::resolved::Dokument> documents;
        database_.getDokumenteAuthor(principal.user_id, request->klientid(), documents);

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
    };

    DocumentService::DocumentService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DocumentService::GetDocument(grpc::ServerContext* context, const triangel::DocumentRequest* request, triangel::DocumentReply* reply) {
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

        database_.getDokumentFile(principal.user_id, dokument, filePath);

        std::ifstream documentFile(filePath, std::ios::binary);

        std::error_code error;
        std::uintmax_t size = std::filesystem::file_size(filePath, error);

        if (!documentFile || error){
        return {grpc::StatusCode::INTERNAL, "Failed to read document"};
        }

        std::string documentData;
        documentData.resize(size);

        if (!documentFile.read(documentData.data(), static_cast<std::streamsize>(size))){
            return {grpc::StatusCode::INTERNAL, "Failed to read document"};
        }

        reply->set_file(std::move(documentData));

        return grpc::Status::OK;
    };

    DeleteDocumentService::DeleteDocumentService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status DeleteDocumentService::DeleteDocument(grpc::ServerContext* context, const triangel::DeleteDocumentRequest* request, triangel::DeleteDocumentReply* reply) {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::Dokument dokument;
        std::string filePath;
        dokument.name = request->dokument().name();
        dokument.gruppe = request->dokument().gruppe().id();
        dokument.klient = request->dokument().klient();

        database_.deleteDokumentFile(principal.user_id, dokument, filePath);

        std::remove(filePath.c_str());

        return grpc::Status::OK;
    };
    
    SendDocumentService::SendDocumentService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status SendDocumentService::SendDocument(grpc::ServerContext* context, const triangel::SendDocumentRequest* request, triangel::SendDocumentReply* reply) {
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

        if (database_.setNewDokumentFile(principal.user_id, dokument, filePath) == 0){
            if(!filePath.empty()){
                std::cerr << "filePath: " << filePath << std::endl;
                std::ofstream documentFile(filePath, std::ios::binary);
                documentFile.write(request->file().data(), request->file().size());
                std::cerr << "rdstate: " << documentFile.rdstate() << std::endl;
                if(documentFile.rdstate() == std::ios_base::goodbit){
                    return grpc::Status::OK;
                }
                return grpc::Status(grpc::StatusCode::INTERNAL, "Writing file failed");
            }
            std::cerr << "Database: " <<  std::endl;
            return grpc::Status(grpc::StatusCode::ALREADY_EXISTS, "Database Error");
        }

        return grpc::Status(grpc::StatusCode::UNKNOWN, "Internal error");
    };


    TaetigkeitService::TaetigkeitService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status TaetigkeitService::Taetigkeit(grpc::ServerContext* context, const triangel::TaetigkeitRequest* request, triangel::TaetigkeitReply* reply) {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }
        std::vector<db::raw::Taetigkeit> taetigkeiten;
        database_.getTaetigkeiten(principal.user_id, taetigkeiten);

        for(int i = 0;i < taetigkeiten.size();i++){
            triangel::Taetigkeit* taetigkeit = reply->add_taetigkeiten();
            taetigkeit->set_id(taetigkeiten.at(i).id);
            taetigkeit->set_bezeichnung(taetigkeiten.at(i).name);
            taetigkeit->set_abrechenbar(taetigkeiten.at(i).abrechenbar);
            taetigkeit->set_buchbar(taetigkeiten.at(i).buchbar);
        }

        return grpc::Status::OK;
    };
    
    ZeiteintraegeService::ZeiteintraegeService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ZeiteintraegeService::Zeiteintraege(grpc::ServerContext* context, const triangel::ZeiteintraegeRequest* request, triangel::ZeiteintraegeReply* reply) {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        std::vector<db::raw::Zeiterfassung> zeiteintraegeVector;
        database_.getZeiteintraege(principal.user_id
            , std::to_string(request->zeiteintragdatum().year()) + "-" + std::to_string(request->zeiteintragdatum().month()) + "-" + std::to_string(request->zeiteintragdatum().day()) + "-00-00"
            , std::to_string(request->zeiteintragdatum().year()) + "-" + std::to_string(request->zeiteintragdatum().month()) + "-" + std::to_string(request->zeiteintragdatum().day()) + "-23-59"
            , zeiteintraegeVector);

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
    };
    
    ZeiteintragService::ZeiteintragService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ZeiteintragService::Zeiteintrag(grpc::ServerContext* context, const triangel::ZeiteintragRequest* request, triangel::ZeiteintragReply* reply) {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }
        
        db::raw::Zeiterfassung zeiteintrag;
        zeiteintrag.von = std::to_string(request->zeiteintrag().dayofentry().year()) + "-" + std::to_string(request->zeiteintrag().dayofentry().month()) + "-" + std::to_string(request->zeiteintrag().dayofentry().day()) + "-" + std::to_string(request->zeiteintrag().anfang().hour()) + "-" + std::to_string(request->zeiteintrag().anfang().minute());
        zeiteintrag.bis = std::to_string(request->zeiteintrag().dayofentry().year()) + "-" + std::to_string(request->zeiteintrag().dayofentry().month()) + "-" + std::to_string(request->zeiteintrag().dayofentry().day()) + "-" + std::to_string(request->zeiteintrag().ende().hour()) + "-" + std::to_string(request->zeiteintrag().ende().minute());
        zeiteintrag.taetigkeit = request->zeiteintrag().taetigkeitid();
        zeiteintrag.klient = request->zeiteintrag().klientid();
        zeiteintrag.beschreibung = request->zeiteintrag().beschreibung();
        zeiteintrag.id = request->zeiteintrag().eintragid();
        
        int rc;

        switch (request->operation())
        {
        case 1:
            rc = database_.addZeiteintrag(principal.user_id, zeiteintrag);
            break;
        case 2:
            rc = database_.changeZeiteintrag(principal.user_id, zeiteintrag);
            break;
        case 3:
            rc = database_.deleteZeiteintrag(principal.user_id, zeiteintrag);
            break;
        
        default:
            rc = -1;
            break;
        }

        switch (rc)
        {
        case 0:
            return grpc::Status::OK;
        case 3:
            return grpc::Status(grpc::StatusCode::ALREADY_EXISTS, "Database Error");
        default:
            return grpc::Status(grpc::StatusCode::UNKNOWN, "Internal error");
        }

    };

    PasswordChangeService::PasswordChangeService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status PasswordChangeService::PasswordChange(grpc::ServerContext* context, const triangel::PasswordChangeRequest* request, triangel::PasswordChangeReply* reply) {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        database_.changePass(principal.user_id, request->oldpassword(), request->newpassword());

        return grpc::Status::OK;
    };

    CreateUserService::CreateUserService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status CreateUserService::CreateUser(grpc::ServerContext* context, const triangel::CreateUserRequest* request, triangel::CreateUserReply* reply) {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::User newUser;
        newUser.login = request->newuser().loginname();
        newUser.email = request->newuser().email();
        newUser.firstName = request->newuser().fname();
        newUser.lastName = request->newuser().lname();
        newUser.role = request->newuser().role();

        int rc = database_.createUserByService(principal.user_id, newUser);

        switch (rc)
        {
        case 0:
            return grpc::Status::OK;
        default:
            return grpc::Status(grpc::StatusCode::UNKNOWN, "Internal error");
        }
    };

    GetUsersService::GetUsersService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status GetUsersService::GetUsers(grpc::ServerContext* context, const triangel::GetUsersRequest* request, triangel::GetUsersReply* reply) {
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
            return grpc::Status(grpc::StatusCode::UNKNOWN, "Internal error");
        }
    };
    

    GetRolesService::GetRolesService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status GetRolesService::GetRoles(grpc::ServerContext* context, const triangel::GetRolesRequest* request, triangel::GetRolesReply* reply) {
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
            return grpc::Status(grpc::StatusCode::UNKNOWN, "Internal error");
        }
    };

    ChangeUserService::ChangeUserService(DatabaseOperator& database, const triangel::auth::JwtManager& jwt) : database_(database), jwt_(jwt) {};

    grpc::Status ChangeUserService::ChangeUser(grpc::ServerContext* context, const triangel::ChangeUserRequest* request, triangel::ChangeUserReply* reply) {
        triangel::auth::Principal principal;
        if (auto status = triangel::auth::requireAuthentication(*context, jwt_, principal); !status.ok()){
            return status;
        }

        db::raw::User changedUser;
        changedUser.id = request->changeduser().id();
        changedUser.login = request->changeduser().loginname();
        changedUser.email = request->changeduser().email();
        changedUser.firstName = request->changeduser().fname();
        changedUser.lastName = request->changeduser().lname();
        changedUser.role = request->changeduser().role();
        changedUser.forceReset = request->forcereset() != 0;

        int rc = database_.changeUser(principal.user_id, changedUser);

        switch (rc)
        {
        case 0:
            return grpc::Status::OK;
        default:
            return grpc::Status(grpc::StatusCode::UNKNOWN, "Internal error");
        }
    };
}