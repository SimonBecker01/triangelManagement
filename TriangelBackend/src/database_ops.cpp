#include "database_ops.hpp"
#include <iostream>
#include <openssl/evp.h>
#include <sstream>
#include <iomanip>


DatabaseOperator::DatabaseOperator(DatabaseManager& dbm) : m_manager(&dbm){
}

DatabaseOperator::~DatabaseOperator(){
}

int DatabaseOperator::createUser(const db::raw::User& user, const std::string& pass)
{
    db::raw::User t_user;

    if(selectUser(user.login, user.id, t_user) != 0){
 
        std::string salt = "";
        salt.reserve(40);

        for(int i = 0;i < 40;i++){
            salt.push_back(std::rand() % 94 + 32);
        }

        
        std::string hash = makeHash(pass, salt);
        
        if(hash.length() == 128){
            
            mysqlx::Session session = m_manager->getSession();

            try {
                mysqlx::SqlStatement query = session.sql(
                    "INSERT INTO Users(Login, last_name, first_name, email, salt, hash, role)"
                    "VALUES (?, ?, ?, ?, ?, ?, ?)"
                );

                mysqlx::SqlResult result = query.bind(user.login).bind(user.lastName).bind(user.firstName).bind(user.email).bind(salt).bind(hash).bind(user.role).execute();

                mysqlx::Row row = result.fetchOne();
                return 0;
            }
            catch (const mysqlx::Error &err) {
                std::cerr << "Database Query Error: " << err.what() << std::endl;
                return 1;
            }

        }
        return 2;

    }

    return 1;
}

int DatabaseOperator::checkUser(const std::string& login, const std::string& pass, int64_t& id, int32_t& forceReset)
{
    db::raw::User user;

    if(selectUser(login, 0, user) == 0){
        if(user.role == 99){
            return 3;
        }
        if(makeHash(pass, user.salt) == user.hash){
            id = user.id;
            forceReset = user.forceReset;
            return 0;
        }
        return 2;
    }

    return 1;
}

int DatabaseOperator::getKlienten(const int64_t user_id, std::vector<db::raw::Klient>& klienten){
    
    mysqlx::Session session = m_manager->getSession();

    try {
        mysqlx::SqlResult result;
        
        mysqlx::SqlStatement query = session.sql(
            "SELECT id, last_name, first_name "
            "FROM Klienten WHERE id IN (SELECT Klient FROM Betreuungen WHERE Betreuer = ?)"
        );
        result = query.bind(user_id).execute();

        
        for(mysqlx::Row row : result) {
            db::raw::Klient nextKlient;

            nextKlient.id = row[0];
            nextKlient.lastName = std::string(row[1]);
            nextKlient.firstName = std::string(row[2]);

            klienten.push_back(nextKlient);

        }
        

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::getMiscValue(const std::string& name, std::string& value)
{
    mysqlx::Session session = m_manager->getSession();

    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT value "
            "FROM Misc WHERE name = ?"
        );
        result = query.bind(name).execute();


        mysqlx::Row row = result.fetchOne();

        if (!row) {
            std::cout << "Misc Value not found: " << name << std::endl;
            return 2;
        }
        
        value = std::string(row[0]);

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::getGruppen(const int64_t id, std::vector<db::raw::Gruppe> & gruppen)
{
    mysqlx::Session session = m_manager->getSession();

    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT id, Name "
            "FROM Gruppe WHERE id IN (SELECT Gruppe FROM RechteGruppe WHERE Rolle = (SELECT role FROM Users WHERE id = ?))"
        );
        result = query.bind(id).execute();

        for(mysqlx::Row row : result) {
            db::raw::Gruppe nextGruppe;

            nextGruppe.id = row[0];
            nextGruppe.name = std::string(row[1]);

            gruppen.push_back(nextGruppe);
        }

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::getKategorien(const int64_t id, std::vector<db::raw::Kategorie> & kategorien)
{
    mysqlx::Session session = m_manager->getSession();

    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT id, Name "
            "FROM Kategorie WHERE id IN (SELECT Kategorie FROM RechteKategorie WHERE Rolle = (SELECT role FROM Users WHERE id = ?))"
        );
        result = query.bind(id).execute();


        for(mysqlx::Row row : result) {
            db::raw::Kategorie nextKategorie;

            nextKategorie.id = row[0];
            nextKategorie.name = std::string(row[1]);

            kategorien.push_back(nextKategorie);

        }

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::getDokumenteAuthor(const int64_t id, const int64_t klient, std::vector<db::resolved::Dokument> & dokumente)
{
    mysqlx::Session session = m_manager->getSession();

    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT d.Name, u.last_name, u.first_name, d.Gruppe, g.Name, d.Kategorie, k.Name "
            "FROM Dokumente d JOIN Users u on d.Author = u.id JOIN Gruppe g ON d.Gruppe = g.id JOIN Kategorie k ON d.Kategorie = k.id "
            "WHERE d.Kategorie IN (SELECT Kategorie FROM RechteKategorie WHERE Rolle = (SELECT role FROM Users WHERE id = ?)) "
            "AND d.Gruppe IN (SELECT Gruppe FROM RechteGruppe WHERE Rolle = (SELECT role FROM Users WHERE id = ?)) "
            "AND d.Klient IN (SELECT Klient FROM Betreuungen WHERE Betreuer = ?) "
            "AND d.Klient = ? "
        );
        result = query.bind(id).bind(id).bind(id).bind(klient).execute();


        for(mysqlx::Row row : result) {
            db::resolved::Dokument nextDokument;

            nextDokument.name = std::string(row[0]);
            nextDokument.authorName = std::string(row[1]) + std::string(row[2]);
            nextDokument.gruppeId = row[3];
            nextDokument.gruppeName = std::string(row[4]);
            nextDokument.kategorieId = row[5];
            nextDokument.kategorieName = std::string(row[6]);

            dokumente.push_back(nextDokument);

        }

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::getDokumentFile(const int64_t id, const db::raw::Dokument dokument, std::string & filepath)
{
    mysqlx::Session session = m_manager->getSession();

    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT d.Datei "
            "FROM Dokumente d "
            "WHERE d.Kategorie IN (SELECT Kategorie FROM RechteKategorie WHERE Rolle = (SELECT role FROM Users WHERE id = ?)) "
            "AND d.Gruppe IN (SELECT Gruppe FROM RechteGruppe WHERE Rolle = (SELECT role FROM Users WHERE id = ?)) "
            "AND d.Klient IN (SELECT Klient FROM Betreuungen WHERE Betreuer = ?) "
            "AND d.Klient = ? "
            "AND d.Gruppe = ? "
            "AND d.Kategorie = ? "
            "AND d.Name = ? "
        );
        result = query.bind(id).bind(id).bind(id).bind(dokument.klient).bind(dokument.gruppe).bind(dokument.kategorie).bind(dokument.name).execute();

        mysqlx::Row row = result.fetchOne();

        if (!row) {
            std::cout << "File not found: " << dokument.name << std::endl;
            return 2;
        }

        filepath = std::string(row[0]);

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::getNewDokumentFile(const int64_t id, const db::raw::Dokument dokument, std::string & filepath)
{
    mysqlx::Session session = m_manager->getSession();

    try {

        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT u.id "
            "FROM Users u "
            "WHERE u.id = ? "
            "AND EXISTS(SELECT Gruppe FROM RechteGruppe WHERE Rolle = u.role AND Gruppe = ?) "
            "AND EXISTS(SELECT Kategorie FROM RechteKategorie WHERE Rolle = u.role AND Kategorie = ?) "
            "AND EXISTS(SELECT Klient FROM Betreuungen WHERE Betreuer = u.id AND Klient = ?) "
            "AND NOT EXISTS(SELECT id FROM Dokumente WHERE Gruppe = ? AND Kategorie = ? AND Klient = ? AND Name = ?) "
        );

        result = query.bind(id).bind(dokument.gruppe).bind(dokument.kategorie).bind(dokument.klient).bind(dokument.gruppe).bind(dokument.kategorie).bind(dokument.klient).bind(dokument.name).execute();

        mysqlx::Row row = result.fetchOne();

        if (!row) {
            std::cout << "Access violation" << std::endl;
            return 2;
        }

        filepath = ("/documents/" + std::to_string(dokument.klient) + "-" + std::to_string(dokument.kategorie) + "-" + std::to_string(dokument.gruppe) + "-" + dokument.name);
        
        query = session.sql(
            "INSERT INTO Dokumente (Name, Datei, Klient, Gruppe, Kategorie, Author) "
            "VALUES(?, ?, ?, ?, ?, ?) "
        );
        result = query.bind(dokument.name).bind(filepath).bind(dokument.klient).bind(dokument.gruppe).bind(dokument.kategorie).bind(id).execute();

        result.getWarningsCount();

        if (result.getWarningsCount() > 0) {
            std::cout << "Could not insert file: " << dokument.name << std::endl;
            filepath = "";
            return 2;
        }

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::getTaetigkeiten(std::vector<db::raw::Taetigkeit> & taetigkeiten)
{
    mysqlx::Session session = m_manager->getSession();

    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT id, Name, Abrechenbar "
            "FROM Taetigkeit "
        );
        result = query.execute();

        for(mysqlx::Row row : result) {
            db::raw::Taetigkeit nextTaetigkeit;

            nextTaetigkeit.id = row[0];
            nextTaetigkeit.name = std::string(row[1]);
            nextTaetigkeit.abrechenbar = bool(row[2]);

            taetigkeiten.push_back(nextTaetigkeit);
        }

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::getZeiteintraege(const int64_t id, const std::string vonDt, const std::string bisDt, std::vector<db::raw::Zeiterfassung> & zeiteintraege)
{
    mysqlx::Session session = m_manager->getSession();
    try {

        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT b.klient, z.taetigkeit, DATE_FORMAT(z.von,'%Y-%m-%d-%H-%i'), DATE_FORMAT(z.bis,'%Y-%m-%d-%H-%i'), z.Beschreibung, z.id "
            "FROM Betreuungen b "
            "JOIN Zeiterfassung z "
            "ON z.Betreuung = b.id "
            "WHERE b.Betreuer = ? "
            "AND z.von >= STR_TO_DATE(?,'%Y-%m-%d-%H-%i') "
            "AND z.bis <= STR_TO_DATE(?,'%Y-%m-%d-%H-%i') "
        );

        result = query.bind(id).bind(vonDt).bind(bisDt).execute();

        for(mysqlx::Row row : result) {
            db::raw::Zeiterfassung nextEintrag;

            nextEintrag.klient = row[0];
            nextEintrag.taetigkeit = row[1];
            nextEintrag.von = std::string(row[2]);
            nextEintrag.bis = std::string(row[3]);
            nextEintrag.beschreibung = std::string(row[4]);
            nextEintrag.id = row[5];


            zeiteintraege.push_back(nextEintrag);
        }

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::addZeiteintrag(const int64_t id, const db::raw::Zeiterfassung neuerEintrag)
{
    mysqlx::Session session = m_manager->getSession();
    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT id "
            "FROM Betreuungen "
            "WHERE Betreuer = ? "
            "AND Klient = ? "
        );
        result = query.bind(id).bind(neuerEintrag.klient).execute();


        mysqlx::Row row = result.fetchOne();

        if (!row) {
            std::cout << "Betreuung not found" << std::endl;
            return 2;
        }
        
        int64_t betreuungId = row[0];
        
        query = session.sql(
            "SELECT z.id "
            "FROM Betreuungen b "
            "JOIN Zeiterfassung z "
            "ON z.Betreuung = b.id "
            "WHERE b.Betreuer = ? "
            "AND z.bis > STR_TO_DATE(?,'%Y-%m-%d-%H-%i') "
            "AND z.von < STR_TO_DATE(?,'%Y-%m-%d-%H-%i') "
        );
        result = query.bind(id).bind(neuerEintrag.von).bind(neuerEintrag.bis).execute();

        row = result.fetchOne();

        if (row) {
            std::cout << "Timeslot overlap" << std::endl;
            return 3;
        }

        query = session.sql(
            "INSERT INTO Zeiterfassung (Betreuung, Taetigkeit, von, bis, Beschreibung) "
            "VALUES (?, ?, STR_TO_DATE(?,'%Y-%m-%d-%H-%i'), STR_TO_DATE(?,'%Y-%m-%d-%H-%i'), ?) "
        );
        result = query.bind(betreuungId).bind(neuerEintrag.taetigkeit).bind(neuerEintrag.von).bind(neuerEintrag.bis).bind(neuerEintrag.beschreibung).execute();

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::changeZeiteintrag(const int64_t id, const db::raw::Zeiterfassung neuerEintrag)
{
    mysqlx::Session session = m_manager->getSession();
    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT id "
            "FROM Betreuungen "
            "WHERE Betreuer = ? "
            "AND Klient = ? "
        );
        result = query.bind(id).bind(neuerEintrag.klient).execute();


        mysqlx::Row row = result.fetchOne();

        if (!row) {
            std::cout << "Betreuung not found" << std::endl;
            return 2;
        }
        
        int64_t betreuungId = row[0];
        
        query = session.sql(
            "SELECT z.id "
            "FROM Betreuungen b "
            "JOIN Zeiterfassung z "
            "ON z.Betreuung = b.id "
            "WHERE b.Betreuer = ? "
            "AND z.bis > STR_TO_DATE(?,'%Y-%m-%d-%H-%i') "
            "AND z.von < STR_TO_DATE(?,'%Y-%m-%d-%H-%i') "
            "AND z.id != ? "
        );
        result = query.bind(id).bind(neuerEintrag.von).bind(neuerEintrag.bis).bind(neuerEintrag.id).execute();

        row = result.fetchOne();

        if (row) {
            std::cout << "Timeslot overlap" << std::endl;
            return 3;
        }

        query = session.sql(
            "UPDATE Zeiterfassung  SET Betreuung = ?, Taetigkeit = ?, von = ?, bis = ?, Beschreibung = ? "
            "WHERE id = ? "
        );
        result = query.bind(betreuungId).bind(neuerEintrag.taetigkeit).bind(neuerEintrag.von).bind(neuerEintrag.bis).bind(neuerEintrag.beschreibung).bind(neuerEintrag.id).execute();

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::deleteZeiteintrag(const int64_t id, const db::raw::Zeiterfassung neuerEintrag)
{
    mysqlx::Session session = m_manager->getSession();
    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT id "
            "FROM Betreuungen "
            "WHERE Betreuer = ? "
            "AND Klient = ? "
        );
        result = query.bind(id).bind(neuerEintrag.klient).execute();


        mysqlx::Row row = result.fetchOne();

        if (!row) {
            std::cout << "Betreuung not found" << std::endl;
            return 2;
        }
        
        int64_t betreuungId = row[0];
        
        query = session.sql(
            "DELETE FROM Zeiterfassung z "
            "WHERE Betreuung = ? "
            "AND id = ? "
        );
        result = query.bind(betreuungId).bind(neuerEintrag.id).execute();

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}

int DatabaseOperator::changePass(const int64_t id, const std::string oldPass, const std::string newPass)
{
    mysqlx::Session session = m_manager->getSession();
    db::raw::User user;
    selectUser("", id, user);

    if( makeHash(oldPass, user.salt) == user.hash){
        try {

            mysqlx::SqlResult result;

            mysqlx::SqlStatement query = session.sql(
                "UPDATE Users "
                "SET hash = ? "
                "WHERE id = ? "
            );
            result = query.bind(makeHash(newPass, user.salt)).bind(id).execute();

            return 0;
        }
        catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
}

std::string DatabaseOperator::makeHash(const std::string& pass, const std::string& salt)
{
    std::string input = pass + salt; // Salzen, später noch pfeffern

    EVP_MD_CTX* context = EVP_MD_CTX_new();
    if (!context) return "";

    unsigned char hash[EVP_MAX_MD_SIZE];
    unsigned int length = 0;

    if (EVP_DigestInit_ex(context, EVP_sha512(), nullptr) &&
        EVP_DigestUpdate(context, input.c_str(), input.length()) &&
        EVP_DigestFinal_ex(context, hash, &length)) 
    {
        EVP_MD_CTX_free(context);
        
        std::stringstream ss;
        for (unsigned int i = 0; i < length; ++i) {
            ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash[i];
        }
        return ss.str();
    }

    EVP_MD_CTX_free(context);
    return "";
}

int DatabaseOperator::selectUser(const std::string& login, const uint64_t& id, db::raw::User& user)
{
    mysqlx::Session session = m_manager->getSession();

    try {
        mysqlx::SqlResult result;
        if(login.length() > 0){
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Login, last_name, first_name, email, salt, hash, role, forceResetPass "
                "FROM Users WHERE Login = ?"
            );
            result = query.bind(login).execute();

        }else{
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Login, last_name, first_name, email, salt, hash, role, forceResetPass "
                "FROM Users WHERE id = ?"
            );
            result = query.bind(id).execute();

        }

        mysqlx::Row row = result.fetchOne();

        if (!row) {
            std::cout << "User not found: " << login << std::endl;
            return 2;
        }
        
        user.id = row[0];
        user.login = std::string(row[1]);
        user.lastName = std::string(row[2]);
        user.firstName = std::string(row[3]);
        user.email = std::string(row[4]);
        user.salt  = std::string(row[5]);
        user.hash  = std::string(row[6]);
        user.role  = int(row[7]);
        user.forceReset  = int(row[8]);

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
}