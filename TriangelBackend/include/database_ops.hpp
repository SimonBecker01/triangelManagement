#pragma once

#include <string>
#include <mysqlx/xdevapi.h>
#include <vector>
#include <utility>
#include "db_struct_raw.hpp"
#include "db_struct_res.hpp"
#include "mailer.hpp"

class DatabaseOperator {
public:
    DatabaseOperator(const std::string&, int);
    ~DatabaseOperator();
    int createUser(const db::raw::User&, const std::string&);
    int checkUser(const std::string&, const std::string&, int64_t&, int32_t&, int32_t&);
    

    int getKlienten(const int64_t, std::vector<db::raw::Klient>&);
    int getRoles(std::vector<std::pair<int8_t, std::string>>&);
    int getTimeBooked(const int32_t, const std::string&, std::vector<std::pair<int8_t, std::string>>&);
    int getSettingsValue(const std::string&, std::string&);
    int getGruppen(const int64_t, std::vector<db::raw::Gruppe>&);
    int getKategorien(const int64_t, std::vector<db::raw::Kategorie>&);
    int getDokumenteAuthor(const int64_t, const int64_t, std::vector<db::resolved::Dokument>&);
    int getDokumentFile(const int64_t, const db::raw::Dokument, std::string&);
    int deleteDokumentFile(const int64_t, const db::raw::Dokument, std::string&);
    int setNewDokumentFile(const int64_t, const db::raw::Dokument, std::string&);
    int getTaetigkeiten(const int64_t, std::vector<db::raw::Taetigkeit>&);
    int getZeiteintraege(const int64_t, const std::string, const std::string, std::vector<db::raw::Zeiterfassung>&);
    int addZeiteintrag(const int64_t, const db::raw::Zeiterfassung);
    int changeZeiteintrag(const int64_t, const db::raw::Zeiterfassung);
    int deleteZeiteintrag(const int64_t, const db::raw::Zeiterfassung);
    int changePass(const int64_t, const std::string, const std::string);
    int createUserByService(const int64_t, const db::raw::User&);
    int getUsersList(const int64_t, std::vector<db::raw::User>&);
    int getRolesList(const int64_t, std::vector<db::raw::Rolle>&);
    int changeUser(const int64_t, const db::raw::User &);
    int getRechteKategorien(const int64_t, std::vector<db::raw::RechteKategorie>&);
    int getRechteGruppe(const int64_t, std::vector<db::raw::RechteGruppe>&);
    int setRechte(const int64_t, const uint64_t, std::vector<uint64_t>&, std::vector<uint64_t>&);
    int changeKategorie(const int64_t, const db::raw::Kategorie&);
    int changeGruppe(const int64_t, const db::raw::Gruppe&);
    int deleteKategorie(const int64_t, const db::raw::Kategorie&);
    int deleteGruppe(const int64_t, const db::raw::Gruppe&);
    int setNewKategorie(const int64_t, const db::raw::Kategorie&);
    int setNewGruppe(const int64_t, const db::raw::Gruppe&);
    int changeTaetigkeit(const int64_t, const db::raw::Taetigkeit&);
    int deleteTaetigkeit(const int64_t, const db::raw::Taetigkeit&);
    int setNewTaetigkeit(const int64_t, const db::raw::Taetigkeit&);
    int getBetreuungen(const int64_t, std::vector<db::raw::Betreuung>&);
    int endBetreuung(const int64_t, const int64_t);
    int setNewBetreuung(const int64_t, const db::raw::Betreuung&);
    int getAuswertungBetreuung(const int64_t, const int64_t, const std::string);
    int getAuswertungBetreuer(const int64_t, const int64_t, const std::string);
    


private:
    std::string makeHash(const std::string&, const std::string&);
    std::string random_string(std::size_t);
    mysqlx::Client m_dbClient;
    mailer::SmtpConfig m_mailConf;

    int selectUser(const std::string&, const uint64_t&, db::raw::User&);
    int resetPasswordAndMail(const uint64_t);
    int checkGF(const uint64_t);
};