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
    services::GetRechteKategorienService getRechteKategorien_service(database, jwt);
    services::GetRechteGruppeService getRechteGruppe_service(database, jwt);
    services::SetRechteService setRechte_service(database, jwt);
    services::ChangeRolleService changeRolle_service(database, jwt);
    services::ChangeKategorieService changeKategorie_service(database, jwt);
    services::ChangeGruppeService changeGruppe_service(database, jwt);
    services::DeleteRolleService deleteRolle_service(database, jwt);
    services::DeleteKategorieService deleteKategorie_service(database, jwt);
    services::DeleteGruppeService deleteGruppe_service(database, jwt);
    services::SetNewRolleService setNewRolle_service(database, jwt);
    services::SetNewKategorieService setNewKategorie_service(database, jwt);
    services::SetNewGruppeService setNewGruppe_service(database, jwt);
    services::ChangeTaetigkeitService changeTaetigkeit_service(database, jwt);
    services::DeleteTaetigkeitService deleteTaetigkeit_service(database, jwt);
    services::SetNewTaetigkeitService setNewTaetigkeit_service(database, jwt);
    services::GetBetreuungenService getBetreuungen_service(database, jwt);
    services::EndBetreuungService endBetreuung_service(database, jwt);
    services::SetNewBetreuungService setNewBetreuung_service(database, jwt);
    services::AuswertungBetreuungService auswertungBetreuung_service(database, jwt);
    services::AuswertungBetreuerService auswertungBetreuer_service(database, jwt);
    services::AuswertungKlientService auswertungKlient_service(database, jwt);
    services::ChangeKlientService changeKlient_service(database, jwt);
    services::DeleteKlientService deleteKlient_service(database, jwt);
    services::SetNewKlientService setNewKlient_service(database, jwt);

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
    builder.RegisterService(&getRechteKategorien_service);
    builder.RegisterService(&getRechteGruppe_service);
    builder.RegisterService(&setRechte_service);
    builder.RegisterService(&changeRolle_service);
    builder.RegisterService(&changeKategorie_service);
    builder.RegisterService(&changeGruppe_service);
    builder.RegisterService(&deleteRolle_service);
    builder.RegisterService(&deleteKategorie_service);
    builder.RegisterService(&deleteGruppe_service);
    builder.RegisterService(&setNewRolle_service);
    builder.RegisterService(&setNewKategorie_service);
    builder.RegisterService(&setNewGruppe_service);
    builder.RegisterService(&changeTaetigkeit_service);
    builder.RegisterService(&deleteTaetigkeit_service);
    builder.RegisterService(&setNewTaetigkeit_service);
    builder.RegisterService(&getBetreuungen_service);
    builder.RegisterService(&endBetreuung_service);
    builder.RegisterService(&setNewBetreuung_service);
    builder.RegisterService(&auswertungBetreuung_service);
    builder.RegisterService(&auswertungBetreuer_service);
    builder.RegisterService(&auswertungKlient_service);
    builder.RegisterService(&changeKlient_service);
    builder.RegisterService(&deleteKlient_service);
    builder.RegisterService(&setNewKlient_service);
    auto server = builder.BuildAndStart();
    if (!server) throw std::runtime_error("gRPC server failed to start");
    std::cout << "TLS gRPC server listening on 0.0.0.0:50051\n";
    server->Wait();
} catch (const std::exception& e) { std::cerr << "Fatal: " << e.what() << '\n'; return 1; }