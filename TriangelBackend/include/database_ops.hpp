#pragma once

#include <string>
#include "database_mgr.hpp"
#include <vector>
#include <utility>
#include "db_struct_raw.hpp"
#include "db_struct_res.hpp"

class DatabaseOperator {
public:
    DatabaseOperator(DatabaseManager&);
    ~DatabaseOperator();
    int createUser(const db::raw::User&, const std::string& pass);
    int checkUser(const std::string&, const std::string&, int64_t&, int32_t&);
    

    int getKlienten(const int64_t, std::vector<db::raw::Klient>&);
    int getRoles(std::vector<std::pair<int8_t, std::string>>&);
    int getTimeBooked(const int32_t, const std::string&, std::vector<std::pair<int8_t, std::string>>&);
    int getMiscValue(const std::string&, std::string&);
    int getGruppen(const int64_t, std::vector<db::raw::Gruppe>&);
    int getKategorien(const int64_t, std::vector<db::raw::Kategorie>&);
    int getDokumenteAuthor(const int64_t, const int64_t, std::vector<db::resolved::Dokument>&);
    int getDokumentFile(const int64_t, const db::raw::Dokument, std::string&);
    int getNewDokumentFile(const int64_t, const db::raw::Dokument, std::string&);
    int getTaetigkeiten(std::vector<db::raw::Taetigkeit>&);
    int getZeiteintraege(const int64_t, const std::string, const std::string, std::vector<db::raw::Zeiterfassung>&);
    int addZeiteintrag(const int64_t, const db::raw::Zeiterfassung);
    int changeZeiteintrag(const int64_t, const db::raw::Zeiterfassung);
    int deleteZeiteintrag(const int64_t, const db::raw::Zeiterfassung);
    int changePass(const int64_t, const std::string, const std::string);
    


private:
    std::string makeHash(const std::string&, const std::string&);
    DatabaseManager* m_manager;

    int selectUser(const std::string& login, const uint64_t& id, db::raw::User& user);
};