#pragma once

#include "grpc_auth.hpp"
#include "jwt_auth.hpp"
#include "triangel.grpc.pb.h"
#include "database_ops.hpp"

#include <cstdlib>
#include <fstream>
#include <stdexcept>


namespace services {

    class AuthServiceImpl final : public triangel::AuthService::Service {
        public:
            AuthServiceImpl(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status Login(grpc::ServerContext*, const triangel::LoginRequest*, triangel::LoginReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class DocumentConfigService final : public triangel::DocumentConfigService::Service {
        public:
            DocumentConfigService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status GetDocumentConfig(grpc::ServerContext*, const triangel::DocumentConfigRequest*, triangel::DocumentConfigReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class DocumentsService final : public triangel::DocumentsService::Service {
        public:
            DocumentsService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status GetDocuments(grpc::ServerContext*, const triangel::DocumentsRequest*, triangel::DocumentsReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class DocumentService final : public triangel::DocumentService::Service {
        public:
            DocumentService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status GetDocument(grpc::ServerContext*, const triangel::DocumentRequest*, triangel::DocumentReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class DeleteDocumentService final : public triangel::DeleteDocumentService::Service {
        public:
            DeleteDocumentService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status DeleteDocument(grpc::ServerContext*, const triangel::DeleteDocumentRequest*, triangel::DeleteDocumentReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class SendDocumentService final : public triangel::SendDocumentService::Service {
        public:
            SendDocumentService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status SendDocument(grpc::ServerContext*, const triangel::SendDocumentRequest*, triangel::SendDocumentReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class TaetigkeitService final : public triangel::TaetigkeitService::Service {
        public:
            TaetigkeitService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status Taetigkeit(grpc::ServerContext*, const triangel::TaetigkeitRequest*, triangel::TaetigkeitReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class ZeiteintraegeService final : public triangel::ZeiteintraegeService::Service {
        public:
            ZeiteintraegeService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status Zeiteintraege(grpc::ServerContext*, const triangel::ZeiteintraegeRequest*, triangel::ZeiteintraegeReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class ZeiteintragService final : public triangel::ZeiteintragService::Service {
        public:
            ZeiteintragService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status Zeiteintrag(grpc::ServerContext*, const triangel::ZeiteintragRequest*, triangel::ZeiteintragReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class PasswordChangeService final : public triangel::PasswordChangeService::Service {
        public:
            PasswordChangeService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status PasswordChange(grpc::ServerContext*, const triangel::PasswordChangeRequest*, triangel::PasswordChangeReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class CreateUserService final : public triangel::CreateUserService::Service {
        public:
            CreateUserService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status CreateUser(grpc::ServerContext*, const triangel::CreateUserRequest*, triangel::CreateUserReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class GetUsersService final : public triangel::GetUsersService::Service {
        public:
            GetUsersService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status GetUsers(grpc::ServerContext*, const triangel::GetUsersRequest*, triangel::GetUsersReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class GetRolesService final : public triangel::GetRolesService::Service {
        public:
            GetRolesService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status GetRoles(grpc::ServerContext*, const triangel::GetRolesRequest*, triangel::GetRolesReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    
    class ChangeUserService final : public triangel::ChangeUserService::Service {
        public:
            ChangeUserService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status ChangeUser(grpc::ServerContext*, const triangel::ChangeUserRequest*, triangel::ChangeUserReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class GetRechteKategorienService final : public triangel::GetRechteKategorienService::Service {
        public:
            GetRechteKategorienService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status GetRechteKategorien(grpc::ServerContext*, const triangel::GetRechteKategorienRequest*, triangel::GetRechteKategorienReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class GetRechteGruppeService final : public triangel::GetRechteGruppeService::Service {
        public:
            GetRechteGruppeService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status GetRechteGruppe(grpc::ServerContext*, const triangel::GetRechteGruppeRequest*, triangel::GetRechteGruppeReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class SetRechteService final : public triangel::SetRechteService::Service {
        public:
            SetRechteService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status SetRechte(grpc::ServerContext*, const triangel::SetRechteRequest*, triangel::SetRechteReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class ChangeKategorieService final : public triangel::ChangeKategorieService::Service {
        public:
            ChangeKategorieService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status ChangeKategorie(grpc::ServerContext*, const triangel::ChangeKategorieRequest*, triangel::ChangeKategorieReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class ChangeGruppeService final : public triangel::ChangeGruppeService::Service {
        public:
            ChangeGruppeService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status ChangeGruppe(grpc::ServerContext*, const triangel::ChangeGruppeRequest*, triangel::ChangeGruppeReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class DeleteKategorieService final : public triangel::DeleteKategorieService::Service {
        public:
            DeleteKategorieService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status DeleteKategorie(grpc::ServerContext*, const triangel::DeleteKategorieRequest*, triangel::DeleteKategorieReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class DeleteGruppeService final : public triangel::DeleteGruppeService::Service {
        public:
            DeleteGruppeService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status DeleteGruppe(grpc::ServerContext*, const triangel::DeleteGruppeRequest*, triangel::DeleteGruppeReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class SetNewKategorieService final : public triangel::SetNewKategorieService::Service {
        public:
            SetNewKategorieService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status SetNewKategorie(grpc::ServerContext*, const triangel::SetNewKategorieRequest*, triangel::SetNewKategorieReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class SetNewGruppeService final : public triangel::SetNewGruppeService::Service {
        public:
            SetNewGruppeService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status SetNewGruppe(grpc::ServerContext*, const triangel::SetNewGruppeRequest*, triangel::SetNewGruppeReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class ChangeTaetigkeitService final : public triangel::ChangeTaetigkeitService::Service {
        public:
            ChangeTaetigkeitService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status ChangeTaetigkeit(grpc::ServerContext*, const triangel::ChangeTaetigkeitRequest*, triangel::ChangeTaetigkeitReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class DeleteTaetigkeitService final : public triangel::DeleteTaetigkeitService::Service {
        public:
            DeleteTaetigkeitService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status DeleteTaetigkeit(grpc::ServerContext*, const triangel::DeleteTaetigkeitRequest*, triangel::DeleteTaetigkeitReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class SetNewTaetigkeitService final : public triangel::SetNewTaetigkeitService::Service {
        public:
            SetNewTaetigkeitService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status SetNewTaetigkeit(grpc::ServerContext*, const triangel::SetNewTaetigkeitRequest*, triangel::SetNewTaetigkeitReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class GetBetreuungenService final : public triangel::GetBetreuungenService::Service {
        public:
            GetBetreuungenService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status GetBetreuungen(grpc::ServerContext*, const triangel::GetBetreuungenRequest*, triangel::GetBetreuungenReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class EndBetreuungService final : public triangel::EndBetreuungService::Service {
        public:
            EndBetreuungService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status EndBetreuung(grpc::ServerContext*, const triangel::EndBetreuungRequest*, triangel::EndBetreuungReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
    class SetNewBetreuungService final : public triangel::SetNewBetreuungService::Service {
        public:
            SetNewBetreuungService(DatabaseOperator&, const triangel::auth::JwtManager&);
            grpc::Status SetNewBetreuung(grpc::ServerContext*, const triangel::SetNewBetreuungRequest*, triangel::SetNewBetreuungReply*) override;
        private: DatabaseOperator& database_; const triangel::auth::JwtManager& jwt_;
    };
}