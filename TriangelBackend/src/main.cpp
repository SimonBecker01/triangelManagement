#include "database_mgr.hpp"
#include "database_ops.hpp"
#include "serviceimplement.hpp"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>


int main() try {
    DatabaseManager database_manager;
    DatabaseOperator database(database_manager);


    triangel::auth::JwtManager jwt(services::requiredEnv("TRIANGEL_JWT_SECRET"), "triangel-backend", "triangel-client", 15 * 60);
    
    services::AuthServiceImpl auth_service(database, jwt);
    services::DocumentConfigService docConfig_service(database, jwt);
    services::DocumentsService docs_service(database, jwt);
    services::DocumentService doc_service(database, jwt);
    services::SendDocumentService sendDoc_service(database, jwt);
    services::TaetigkeitService taet_service(database, jwt);
    services::ZeiteintraegeService zeitEintrae(database, jwt);
    services::ZeiteintragService zeitEintra(database, jwt);
    services::PasswordChangeService passCha_service(database, jwt);

    grpc::ServerBuilder builder;

    std::cerr << "TLS cert: " << services::requiredEnv("TRIANGEL_TLS_CERT") << '\n';
    std::cerr << "TLS key : " << services::requiredEnv("TRIANGEL_TLS_KEY") << '\n';

    builder.AddListeningPort("0.0.0.0:50051", services::tlsCredentials());
    builder.RegisterService(&auth_service);
    builder.RegisterService(&docConfig_service);
    builder.RegisterService(&docs_service);
    builder.RegisterService(&doc_service);
    builder.RegisterService(&sendDoc_service);
    builder.RegisterService(&taet_service);
    builder.RegisterService(&zeitEintrae);
    builder.RegisterService(&zeitEintra);
    builder.RegisterService(&passCha_service);
    auto server = builder.BuildAndStart();
    if (!server) throw std::runtime_error("gRPC server failed to start");
    std::cout << "TLS gRPC server listening on 0.0.0.0:50051\n";
    server->Wait();
} catch (const std::exception& e) { std::cerr << "Fatal: " << e.what() << '\n'; return 1; }