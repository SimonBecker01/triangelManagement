#include <cstdlib>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>

#include "database_ops.hpp"
#include "serviceimplement.hpp"
#include "utils.hpp"




int main() try {




    DatabaseOperator database(utils::load_credential("db_cred"), 20);

    /*
    //only for first run on dev system
    db::raw::User newUser;
    newUser.login = "Geschäftsführer";
    newUser.email = "später";
    newUser.firstName = "K";
    newUser.lastName = "V";
    newUser.role = 1;

    database.createUser(newUser, "Passwort1");
    */

    triangel::auth::JwtManager jwt(utils::load_credential("jwt_secret"), "triangel-backend", "triangel-client", 15 * 60);
    
    services::AuthServiceImpl auth_service(database, jwt);
    services::DocumentConfigService docConfig_service(database, jwt);
    services::DocumentsService docs_service(database, jwt);
    services::DocumentService doc_service(database, jwt);
    services::DeleteDocumentService delDoc_service(database, jwt);
    services::SendDocumentService sendDoc_service(database, jwt);
    services::TaetigkeitService taet_service(database, jwt);
    services::ZeiteintraegeService zeitEintrae(database, jwt);
    services::ZeiteintragService zeitEintra(database, jwt);
    services::PasswordChangeService passCha_service(database, jwt);
    services::CreateUserService createUser_service(database, jwt);
    services::GetUsersService getUsers_service(database, jwt);
    services::GetRolesService getRoles_service(database, jwt);
    services::ChangeUserService changeUser_service(database, jwt);

    grpc::ServerBuilder builder;

    builder.AddListeningPort("0.0.0.0:50051", utils::tlsCredentials());
    builder.RegisterService(&auth_service);
    builder.RegisterService(&docConfig_service);
    builder.RegisterService(&docs_service);
    builder.RegisterService(&doc_service);
    builder.RegisterService(&delDoc_service);
    builder.RegisterService(&sendDoc_service);
    builder.RegisterService(&taet_service);
    builder.RegisterService(&zeitEintrae);
    builder.RegisterService(&zeitEintra);
    builder.RegisterService(&passCha_service);
    builder.RegisterService(&createUser_service);
    builder.RegisterService(&getUsers_service);
    builder.RegisterService(&getRoles_service);
    builder.RegisterService(&changeUser_service);
    auto server = builder.BuildAndStart();
    if (!server) throw std::runtime_error("gRPC server failed to start");
    std::cout << "TLS gRPC server listening on 0.0.0.0:50051\n";
    server->Wait();
} catch (const std::exception& e) { std::cerr << "Fatal: " << e.what() << '\n'; return 1; }