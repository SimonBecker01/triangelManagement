#pragma once

#include "grpc_auth.hpp"
#include "jwt_auth.hpp"
#include "triangel.grpc.pb.h"
#include "database_ops.hpp"

#include <cstdlib>
#include <fstream>
#include <stdexcept>


namespace services {
    std::string requiredEnv(const char*);
    std::string readFile(const std::string&);

    std::shared_ptr<grpc::ServerCredentials> tlsCredentials();

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
    
}