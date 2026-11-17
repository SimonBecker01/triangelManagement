#include "database_ops.hpp"

#include <iostream>
#include <openssl/evp.h>
#include <sstream>
#include <iomanip>
#include <openssl/rand.h>
#include <openssl/crypto.h>
#include <algorithm>
#include <filesystem>
#include <cstdlib>
#include <set>
#include <stdexcept>

namespace {
class Transaction {
public:
    explicit Transaction(mysqlx::Session& session) : session_(session) { session_.startTransaction(); }
    ~Transaction() { if (!committed_) { try { session_.rollback(); } catch (...) {} } }
    void commit() { session_.commit(); committed_ = true; }
    Transaction(const Transaction&) = delete;
    Transaction& operator=(const Transaction&) = delete;
private:
    mysqlx::Session& session_;
    bool committed_ = false;
};
}

DatabaseOperator::DatabaseOperator(const std::string& conString, int numbCon) : m_dbClient(conString, mysqlx::ClientOption::POOL_MAX_SIZE, numbCon){
    mailer::init();
    // A missing mail configuration must not crash read-only services, but
    // mail-dependent operations will return an error instead of pretending success.
    std::string mailError;
    if (!mailer::SmtpConfig::load(m_mailConf, &mailError))
        std::cerr << "SMTP is unavailable: " << mailError << std::endl;
}

DatabaseOperator::~DatabaseOperator(){
    try { m_dbClient.close(); }
    catch (const std::exception& e) { std::cerr << "Closing database pool failed: " << e.what() << std::endl; }
    catch (...) { std::cerr << "Closing database pool failed" << std::endl; }
    mailer::cleanup();
}

int DatabaseOperator::createUser(const db::raw::User& user, const std::string& pass)
try
{
    db::raw::User t_user;

    if(selectUser(user.login, user.id, t_user) == 2){
 
        std::string salt = random_string(std::size_t(20));
        
        std::string hash = makeHash(pass, salt);
        
        if(hash.length() == 128){
            
            mysqlx::Session session = m_dbClient.getSession();

            try {
                mysqlx::SqlStatement query = session.sql(
                    "INSERT INTO Users(Login, Nachname, Vorname, Email, salt, hash, Rolle)"
                    "VALUES (?, ?, ?, ?, ?, ?, ?)"
                );

                mysqlx::SqlResult result = query.bind(user.login).bind(user.lastName).bind(user.firstName).bind(user.email).bind(salt).bind(hash).bind(user.role).execute();

                // INSERT has no result rows; fetching one would report a false failure.
                return result.getAffectedItemsCount() == 1 ? 0 : 1;
            }
            catch (const mysqlx::Error &err) {
                std::cerr << "Database Query Error: " << err.what() << std::endl;
                return 1;
            }

        }
        return 2;

    }

    return 1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::checkUser(const std::string& login, const std::string& pass, int64_t& id, int32_t& forceReset, int32_t& role)
try
{
    db::raw::User user;
    const int rc = selectUser(login, 0, user);
    if (rc == 1) return -1;  // database unavailable, not invalid credentials
    if (rc != 0) return 1;
    if (user.role == 99) return 3;
    const std::string hash = makeHash(pass, user.salt);
    if (hash.size() != user.hash.size() || hash.empty() ||
        CRYPTO_memcmp(hash.data(), user.hash.data(), hash.size()) != 0) return 2;
    id = user.id;
    forceReset = user.forceReset;
    role = user.role;
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::getKlienten(const int64_t user_id, std::vector<db::raw::Klient>& klienten)try
{
    
    int rc = checkGF(user_id);
    if (rc == 1) return 1;

    mysqlx::Session session = m_dbClient.getSession();

    try {
        mysqlx::SqlResult result;
        if(rc != 0){
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Nachname, Vorname "
                "FROM Klienten "
                "WHERE id IN (SELECT Klient FROM Betreuungen WHERE Betreuer = ?) "
                "AND id != 0 "
            );
            result = query.bind(user_id).execute();
        }else{
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Nachname, Vorname "
                "FROM Klienten "
                "WHERE id != 0 "
            );
            result = query.execute();
        }

        
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
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::getSettingsValue(const std::string& name, std::string& value)
try
{
    mysqlx::Session session = m_dbClient.getSession();

    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT Wert "
            "FROM Systemeinstellungen WHERE Name = ?"
        );
        result = query.bind(name).execute();


        mysqlx::Row row = result.fetchOne();

        if (!row) {
            std::cout << "Settings Value not found: " << name << std::endl;
            return 2;
        }
        
        // Systemeinstellungen.Wert is BIGINT, not a string.
        value = std::string(row[0]);

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::setSettingsValue(const int64_t id, const std::string& name, const std::string& value)
try
{
    int rc = checkGF(id);
    if(rc != 0) return rc;
    mysqlx::Session session = m_dbClient.getSession();

    try {
        mysqlx::SqlResult result;


        mysqlx::SqlStatement query = session.sql(
            "SELECT Wert "
            "FROM Systemeinstellungen WHERE Name = ? "
        );
        result = query.bind(name).execute();


        mysqlx::Row row = result.fetchOne();

        if (!row) {
            query = session.sql(
                "INSERT INTO Systemeinstellungen(Name, Wert) "
                "VALUES(?, ?) "
            );
            result = query.bind(name).bind(value).execute();
            if(result.getWarningsCount() > 0) return 1;
            return 4;
        }else{
            query = session.sql(
                "UPDATE Systemeinstellungen "
                "SET Wert = ? "
                "WHERE Name = ?"
            );
            result = query.bind(value).bind(name).execute();
            if(result.getWarningsCount() > 0) return 1;
            return 5;
        }
        

        return 0;
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::getGruppen(const int64_t id, std::vector<db::raw::Gruppe> & gruppen)
try
{
    int rc = checkGF(id);
    if (rc == 1) return 1;

    mysqlx::Session session = m_dbClient.getSession();

    try {
        mysqlx::SqlResult result;
        
        if(rc != 0){
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Name "
                "FROM Gruppe WHERE id IN (SELECT Gruppe FROM RechteGruppe WHERE Rolle = (SELECT Rolle FROM Users WHERE id = ?)) "
            );
            result = query.bind(id).execute();
        }else{
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Name "
                "FROM Gruppe "
            );
            result = query.execute();
        }

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
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::getKategorien(const int64_t id, std::vector<db::raw::Kategorie> & kategorien)
try
{
    int rc = checkGF(id);
    if (rc == 1) return 1;

    mysqlx::Session session = m_dbClient.getSession();

    try {
        mysqlx::SqlResult result;
        
        if(rc != 0){
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Name "
                "FROM Kategorie WHERE id IN (SELECT Kategorie FROM RechteKategorie WHERE Rolle = (SELECT Rolle FROM Users WHERE id = ?)) "
            );
            result = query.bind(id).execute();
        }else{
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Name "
                "FROM Kategorie "
            );
            result = query.execute();
        }


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
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

// CHANGE: access is derived from database permissions, not client-provided
// categories. Client 0 denotes common documents; role 1 is the administrator.
int DatabaseOperator::getDokumenteAuthor(const int64_t id, const int64_t klient, std::vector<db::resolved::Dokument>& dokumente)
try
{
    const int rc = checkGF(id);
    if (rc == 1) return 1;
    const int admin = rc == 0 ? 1 : 0;
    mysqlx::Session session = m_dbClient.getSession();
    auto result = session.sql(
        "SELECT d.Name, u.Login, d.Gruppe, g.Name, d.id "
        "FROM Dokumente d JOIN Users u ON d.Autor = u.id JOIN Gruppe g ON d.Gruppe = g.id "
        "WHERE d.Klient = ? "
        "AND (d.Klient = 0 OR ? = 1 OR EXISTS (SELECT 1 FROM Betreuungen b WHERE b.Betreuer = ? AND b.Klient = d.Klient)) "
        "AND (? = 1 OR EXISTS (SELECT 1 FROM RechteGruppe rg JOIN Users me ON me.Rolle = rg.Rolle WHERE me.id = ? AND rg.Gruppe = d.Gruppe)) "
        "AND (? = 1 OR EXISTS (SELECT 1 FROM Kategorienzuordnung kz JOIN RechteKategorie rk ON rk.Kategorie = kz.Kategorie JOIN Users me ON me.Rolle = rk.Rolle WHERE me.id = ? AND kz.Dokument = d.id)) "
        "ORDER BY d.Name"
    ).bind(klient).bind(admin).bind(id).bind(admin).bind(id).bind(admin).bind(id).execute();
    // Materialize the outer query before executing nested queries on this session.
    std::vector<mysqlx::Row> rows;
    for (mysqlx::Row row : result) rows.push_back(row);
    for (const auto& row : rows) {
        db::resolved::Dokument doc;
        doc.name = std::string(row[0]);
        doc.authorName = std::string(row[1]);
        doc.gruppeId = row[2];
        doc.gruppeName = std::string(row[3]);
        doc.id = row[4];
        auto cats = session.sql(
            "SELECT k.id, k.Name FROM Kategorie k JOIN Kategorienzuordnung kz ON kz.Kategorie = k.id "
            "WHERE kz.Dokument = ? AND (? = 1 OR EXISTS "
            "(SELECT 1 FROM RechteKategorie rk JOIN Users u ON u.Rolle = rk.Rolle WHERE u.id = ? AND rk.Kategorie = k.id)) ORDER BY k.Name"
        ).bind(doc.id).bind(admin).bind(id).execute();
        for (mysqlx::Row category : cats) {
            doc.kategorieId.push_back(category[0]);
            doc.kategorieName.push_back(std::string(category[1]));
        }
        dokumente.push_back(std::move(doc));
    }
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::getDokumentFile(const int64_t id, const db::raw::Dokument dokument, std::string& filepath)
try
{
    const int rc = checkGF(id);
    if (rc == 1) return 1;
    const int admin = rc == 0 ? 1 : 0;
    mysqlx::Session session = m_dbClient.getSession();
    auto result = session.sql("SELECT d.id, d.Datei FROM Dokumente d WHERE d.Klient = ? AND d.Gruppe = ? AND d.Name = ? "
        "AND (d.Klient = 0 OR ? = 1 OR EXISTS (SELECT 1 FROM Betreuungen b WHERE b.Betreuer = ? AND b.Klient = d.Klient)) "
        "AND (? = 1 OR EXISTS (SELECT 1 FROM RechteGruppe rg JOIN Users me ON me.Rolle = rg.Rolle WHERE me.id = ? AND rg.Gruppe = d.Gruppe)) "
        "AND (? = 1 OR EXISTS (SELECT 1 FROM Kategorienzuordnung kz JOIN RechteKategorie rk ON rk.Kategorie = kz.Kategorie JOIN Users me ON me.Rolle = rk.Rolle WHERE me.id = ? AND kz.Dokument = d.id))")
        .bind(dokument.klient).bind(dokument.gruppe).bind(dokument.name)
        .bind(admin).bind(id).bind(admin).bind(id).bind(admin).bind(id).execute();
    auto row = result.fetchOne();
    if (!row) return 2;
    filepath = std::string(row[1]);
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::deleteDokumentFile(const int64_t id, const db::raw::Dokument dokument, std::string& filepath)
try
{
    const int rc = checkGF(id);
    if (rc == 1) return 1;
    const int admin = rc == 0 ? 1 : 0;
    mysqlx::Session session = m_dbClient.getSession();
    Transaction tx(session);
    auto result = session.sql("SELECT d.id, d.Datei FROM Dokumente d WHERE d.Klient = ? AND d.Gruppe = ? AND d.Name = ? "
        "AND (d.Klient = 0 OR ? = 1 OR EXISTS (SELECT 1 FROM Betreuungen b WHERE b.Betreuer = ? AND b.Klient = d.Klient)) "
        "AND (? = 1 OR EXISTS (SELECT 1 FROM RechteGruppe rg JOIN Users me ON me.Rolle = rg.Rolle WHERE me.id = ? AND rg.Gruppe = d.Gruppe)) "
        "AND (? = 1 OR EXISTS (SELECT 1 FROM Kategorienzuordnung kz JOIN RechteKategorie rk ON rk.Kategorie = kz.Kategorie JOIN Users me ON me.Rolle = rk.Rolle WHERE me.id = ? AND kz.Dokument = d.id))" " FOR UPDATE")
        .bind(dokument.klient).bind(dokument.gruppe).bind(dokument.name)
        .bind(admin).bind(id).bind(admin).bind(id).bind(admin).bind(id).execute();
    auto row = result.fetchOne();
    if (!row) return 2;
    const uint64_t documentId = row[0];
    filepath = std::string(row[1]);
    auto removed = session.sql("DELETE FROM Dokumente WHERE id = ?").bind(documentId).execute();
    if (removed.getAffectedItemsCount() != 1) return 2;
    tx.commit();
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::setNewDokumentFile(const int64_t id, const db::raw::Dokument dokument, std::string& filepath)
try
{
    if (dokument.name.empty() || dokument.name.size() > 255 || dokument.gruppe == 0 || dokument.kategorie.empty() || dokument.kategorie.size() > 256)
        return 2;
    const int rc = checkGF(id);
    if (rc == 1) return 1;
    const int admin = rc == 0 ? 1 : 0;
    mysqlx::Session session = m_dbClient.getSession();
    Transaction tx(session);
    auto permitted = session.sql(
        "SELECT u.id FROM Users u WHERE u.id = ? "
        "AND (? = 1 OR EXISTS (SELECT 1 FROM RechteGruppe rg WHERE rg.Rolle = u.Rolle AND rg.Gruppe = ?)) "
        "AND (? = 0 OR ? = 1 OR EXISTS (SELECT 1 FROM Betreuungen b WHERE b.Betreuer = u.id AND b.Klient = ?)) "
        "AND NOT EXISTS (SELECT 1 FROM Dokumente d WHERE d.Gruppe = ? AND d.Klient = ? AND d.Name = ?)"
    ).bind(id).bind(admin).bind(dokument.gruppe).bind(dokument.klient).bind(admin).bind(dokument.klient)
     .bind(dokument.gruppe).bind(dokument.klient).bind(dokument.name).execute();
    if (!permitted.fetchOne()) return 2;
    std::set<uint64_t> categories(dokument.kategorie.begin(), dokument.kategorie.end());
    for (auto category : categories) {
        auto allowed = session.sql(
            "SELECT k.id FROM Kategorie k WHERE k.id = ? AND (? = 1 OR EXISTS "
            "(SELECT 1 FROM RechteKategorie rk JOIN Users u ON u.Rolle = rk.Rolle WHERE u.id = ? AND rk.Kategorie = k.id))"
        ).bind(category).bind(admin).bind(id).execute();
        if (!allowed.fetchOne()) return 2;
    }
    // Never use a client-supplied name as a path. The random storage name also
    // avoids traversal and collisions between otherwise valid display names.
    const char* configuredDir = std::getenv("TRIANGEL_DOCUMENT_DIR");
    const std::filesystem::path root = configuredDir && *configuredDir ? configuredDir : "/documents";
    filepath = (root / (random_string(24) + ".bin")).string();
    session.sql("INSERT INTO Dokumente (Name, Datei, Klient, Gruppe, Autor) VALUES (?, ?, ?, ?, ?)")
        .bind(dokument.name).bind(filepath).bind(dokument.klient).bind(dokument.gruppe).bind(id).execute();
    auto inserted = session.sql("SELECT id FROM Dokumente WHERE Datei = ?").bind(filepath).execute();
    auto row = inserted.fetchOne();
    if (!row) return 1;
    const uint64_t documentId = row[0];
    for (auto category : categories)
        session.sql("INSERT INTO Kategorienzuordnung (Kategorie, Dokument) VALUES (?, ?)").bind(category).bind(documentId).execute();
    tx.commit();
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::getTaetigkeiten(const int64_t id, std::vector<db::raw::Taetigkeit> & taetigkeiten)
try
{
    int rc = checkGF(id);
    if (rc == 1) return 1;

    mysqlx::Session session = m_dbClient.getSession();
    mysqlx::SqlResult result;

    if(rc != 0){
        try {
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Name, Abrechenbar "
                "FROM Taetigkeit "
                "WHERE Buchbar = 1 "
            );
            result = query.execute();

            for(mysqlx::Row row : result) {
                db::raw::Taetigkeit nextTaetigkeit;

                nextTaetigkeit.id = row[0];
                nextTaetigkeit.name = std::string(row[1]);
                nextTaetigkeit.abrechenbar = bool(row[2]);
                nextTaetigkeit.buchbar = true;

                taetigkeiten.push_back(nextTaetigkeit);
            }

            return 0;
        }
        catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }else{

        try {
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Name, Abrechenbar, Buchbar "
                "FROM Taetigkeit "
            );
            result = query.execute();

            for(mysqlx::Row row : result) {
                db::raw::Taetigkeit nextTaetigkeit;

                nextTaetigkeit.id = row[0];
                nextTaetigkeit.name = std::string(row[1]);
                nextTaetigkeit.abrechenbar = bool(row[2]);
                nextTaetigkeit.buchbar = bool(row[3]);

                taetigkeiten.push_back(nextTaetigkeit);
            }

            return 0;
        }
        catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }
    
    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::getZeiteintraege(const int64_t id, const std::string vonDt, const std::string bisDt, std::vector<db::raw::Zeiterfassung> & zeiteintraege)
try
{
    mysqlx::Session session = m_dbClient.getSession();
    try {

        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT b.Klient, z.Taetigkeit, DATE_FORMAT(z.Von,'%Y-%m-%d-%H-%i'), DATE_FORMAT(z.Bis,'%Y-%m-%d-%H-%i'), z.Beschreibung, z.id "
            "FROM Betreuungen b "
            "JOIN Zeiterfassung z "
            "ON z.Betreuung = b.id "
            "WHERE b.Betreuer = ? "
            "AND z.Von >= STR_TO_DATE(?,'%Y-%m-%d-%H-%i') "
            "AND z.Bis <= STR_TO_DATE(?,'%Y-%m-%d-%H-%i') "
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
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

namespace {
int saveTimeEntry(mysqlx::Client& client, int64_t userId, const db::raw::Zeiterfassung& entry, std::string& ec, bool update)
{
    ec.clear();
    if (entry.von.size() != 16 || entry.bis.size() != 16 || entry.von >= entry.bis || entry.klient == 0 || entry.taetigkeit == 0 || (update && entry.id == 0)) {
        ec = "Ungültige Zeitangaben oder Auswahl.";
        return 3;
    }
    mysqlx::Session session = client.getSession();
    Transaction tx(session);
    if (!session.sql("SELECT id FROM Users WHERE id = ? FOR UPDATE").bind(userId).execute().fetchOne()) return 2;
    if (update) {
        auto own = session.sql("SELECT z.id FROM Zeiterfassung z JOIN Betreuungen b ON b.id = z.Betreuung WHERE z.id = ? AND b.Betreuer = ?")
            .bind(entry.id).bind(userId).execute();
        if (!own.fetchOne()) return 2;
    }
    const std::string month = entry.von.substr(0, 8) + "01";
    auto care = session.sql(
        "SELECT id, Wochenstunden, DATEDIFF(GueltigVon, STR_TO_DATE(?,'%Y-%m-%d')), "
        "DATEDIFF(LAST_DAY(STR_TO_DATE(?,'%Y-%m-%d')), GueltigBis), "
        "TIME_TO_SEC(TIMEDIFF(STR_TO_DATE(?,'%Y-%m-%d-%H-%i'), STR_TO_DATE(?,'%Y-%m-%d-%H-%i'))) "
        "FROM Betreuungen WHERE Betreuer = ? AND Klient = ? "
        "AND GueltigVon <= DATE(STR_TO_DATE(?,'%Y-%m-%d-%H-%i')) "
        "AND GueltigBis >= DATE(STR_TO_DATE(?,'%Y-%m-%d-%H-%i')) ORDER BY GueltigVon DESC LIMIT 1"
    ).bind(month).bind(month).bind(entry.bis).bind(entry.von).bind(userId).bind(entry.klient).bind(entry.von).bind(entry.bis).execute();
    auto row = care.fetchOne();
    if (!row || row[4].isNull()) { ec = "Keine gültige Betreuung gefunden."; return 2; }
    const int64_t careId = row[0], weeklyMinutes = row[1], before = row[2], after = row[3], requestedSeconds = row[4];
    if (requestedSeconds <= 0) { ec = "Das Ende muss nach dem Anfang liegen."; return 3; }
    const int64_t missing = std::max<int64_t>(0, before) + std::max<int64_t>(0, after);
    const double monthlyMinutes = std::max(0.0, ((4.3 * weeklyMinutes) / 30.4) * (30.4 - missing));
    auto overlap = session.sql(
        "SELECT z.id FROM Zeiterfassung z JOIN Betreuungen b ON z.Betreuung = b.id "
        "WHERE b.Betreuer = ? AND z.Bis > STR_TO_DATE(?,'%Y-%m-%d-%H-%i') "
        "AND z.Von < STR_TO_DATE(?,'%Y-%m-%d-%H-%i') AND z.id <> ? LIMIT 1"
    ).bind(userId).bind(entry.von).bind(entry.bis).bind(update ? entry.id : 0).execute();
    if (overlap.fetchOne()) { ec = "Überschneidung mit einem bestehenden Eintrag."; return 3; }
    auto activity = session.sql("SELECT Abrechenbar FROM Taetigkeit WHERE id = ?").bind(entry.taetigkeit).execute();
    auto activityRow = activity.fetchOne();
    if (!activityRow) { ec = "Tätigkeit nicht gefunden."; return 2; }
    if (static_cast<int>(activityRow[0]) != 0) {
        auto total = session.sql(
            // MySQL SUM returns DECIMAL, which X DevAPI cannot cast to int64.
            "SELECT CAST(COALESCE(SUM(TIME_TO_SEC(TIMEDIFF(z.Bis,z.Von))),0) AS SIGNED) FROM Zeiterfassung z "
            "JOIN Taetigkeit t ON z.Taetigkeit = t.id WHERE z.Betreuung = ? AND z.id <> ? AND t.Abrechenbar = true "
            "AND z.Von >= STR_TO_DATE(?,'%Y-%m-%d') AND z.Von < DATE_ADD(LAST_DAY(STR_TO_DATE(?,'%Y-%m-%d')), INTERVAL 1 DAY)"
        ).bind(careId).bind(update ? entry.id : 0).bind(month).bind(month).execute();
        auto totalRow = total.fetchOne();
        const int64_t usedSeconds = totalRow ? static_cast<int64_t>(totalRow[0]) : 0;
        if (usedSeconds + requestedSeconds > monthlyMinutes * 60) {
            ec = "Die verfügbaren Monatsstunden dieser Betreuung werden überschritten.";
            return 3;
        }
    }
    if (update) {
        session.sql("UPDATE Zeiterfassung SET Betreuung = ?, Taetigkeit = ?, Von = STR_TO_DATE(?,'%Y-%m-%d-%H-%i'), Bis = STR_TO_DATE(?,'%Y-%m-%d-%H-%i'), Beschreibung = ? WHERE id = ?")
            .bind(careId).bind(entry.taetigkeit).bind(entry.von).bind(entry.bis).bind(entry.beschreibung).bind(entry.id).execute();
    } else {
        session.sql("INSERT INTO Zeiterfassung (Betreuung, Taetigkeit, Von, Bis, Beschreibung) VALUES (?, ?, STR_TO_DATE(?,'%Y-%m-%d-%H-%i'), STR_TO_DATE(?,'%Y-%m-%d-%H-%i'), ?)")
            .bind(careId).bind(entry.taetigkeit).bind(entry.von).bind(entry.bis).bind(entry.beschreibung).execute();
    }
    tx.commit();
    return 0;
}
}

int DatabaseOperator::addZeiteintrag(const int64_t id, const db::raw::Zeiterfassung eintrag, std::string& ec)
try
{
    return saveTimeEntry(m_dbClient, id, eintrag, ec, false);
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::changeZeiteintrag(const int64_t id, const db::raw::Zeiterfassung eintrag, std::string& ec)
try
{
    return saveTimeEntry(m_dbClient, id, eintrag, ec, true);
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::deleteZeiteintrag(const int64_t id, const db::raw::Zeiterfassung eintrag)
try
{
    mysqlx::Session session = m_dbClient.getSession();
    auto result = session.sql("DELETE FROM Zeiterfassung WHERE id = ? AND Betreuung IN (SELECT id FROM Betreuungen WHERE Betreuer = ?)")
        .bind(eintrag.id).bind(id).execute();
    return result.getAffectedItemsCount() == 1 ? 0 : 2;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::changePass(const int64_t id, const std::string oldPass, const std::string newPass)
try
{
    mysqlx::Session session = m_dbClient.getSession();
    db::raw::User user;
    const int userRc = selectUser("", id, user);
    if (userRc != 0) return userRc == 1 ? 1 : 2;

    const std::string oldHash = makeHash(oldPass, user.salt);
    if (!oldHash.empty() && oldHash.size() == user.hash.size() &&
        CRYPTO_memcmp(oldHash.data(), user.hash.data(), oldHash.size()) == 0) {
        try {

            mysqlx::SqlResult result;

            mysqlx::SqlStatement query = session.sql(
                "UPDATE Users "
                "SET hash = ?, forceResetPass = 0 "
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
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::createUserByService(const int64_t id, const db::raw::User & newUser)
try
{
    const int rc = checkGF(id);
    if (rc != 0) return rc;
    if (newUser.login.empty() || newUser.firstName.empty() || newUser.lastName.empty() || newUser.email.empty() || newUser.role == 0) return 2;
    db::raw::User existing;
    const int lookup = selectUser(newUser.login, 0, existing);
    if (lookup == 0) return 2;
    if (lookup != 2) return 1;
    const std::string password = random_string(10);
    const std::string salt = random_string(20);
    const std::string hash = makeHash(password, salt);
    if (hash.size() != 128) return 1;
    mysqlx::Session session = m_dbClient.getSession();
    Transaction tx(session);
    session.sql("INSERT INTO Users(Login, Nachname, Vorname, Email, salt, hash, Rolle, forceResetPass) VALUES (?, ?, ?, ?, ?, ?, ?, 1)")
        .bind(newUser.login).bind(newUser.lastName).bind(newUser.firstName).bind(newUser.email).bind(salt).bind(hash).bind(newUser.role).execute();
    // Keep database changes uncommitted if SMTP fails. Email and MySQL cannot be
    // made fully atomic: a commit failure after successful SMTP requires admin recovery.
    std::string mailError;
    if (!mailer::sendPasswordReset(m_mailConf, newUser.email, password, &mailError)) return 1;
    tx.commit();
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::getUsersList(const int64_t id, std::vector<db::raw::User> & userList)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{
            
        try {
            mysqlx::Session session = m_dbClient.getSession();
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Login, Nachname, Vorname, Email, Rolle "
                "FROM Users "
            );
            mysqlx::SqlResult result = query.execute();

            for(mysqlx::Row row : result) {
                db::raw::User nextEintrag;

                nextEintrag.id = row[0];
                nextEintrag.login = std::string(row[1]);
                nextEintrag.lastName = std::string(row[2]);
                nextEintrag.firstName = std::string(row[3]);
                nextEintrag.email = std::string(row[4]);
                nextEintrag.role = (int32_t)row[5];

                userList.push_back(nextEintrag);
            }

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::getRolesList(const int64_t id, std::vector<db::raw::Rolle> & roleList)
try
{

    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        try {
            mysqlx::Session session = m_dbClient.getSession();
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Rolle "
                "FROM Rollen "
            );
            mysqlx::SqlResult result = query.execute();

            for(mysqlx::Row row : result) {
                db::raw::Rolle nextEintrag;

                nextEintrag.id = (int32_t)row[0];
                nextEintrag.rolle = std::string(row[1]);

                roleList.push_back(nextEintrag);
            }

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::changeUser(const int64_t id, const db::raw::User & changedUser)
try
{
    const int rc = checkGF(id);
    if (rc != 0) return rc;
    if (changedUser.id == 0 || changedUser.login.empty() || changedUser.firstName.empty() || changedUser.lastName.empty() || changedUser.email.empty() || changedUser.role == 0) return 2;
    mysqlx::Session session = m_dbClient.getSession();
    Transaction tx(session);
    auto user = session.sql("SELECT salt, forceResetPass FROM Users WHERE id = ? FOR UPDATE").bind(changedUser.id).execute().fetchOne();
    if (!user) return 2;
    const std::string salt = std::string(user[0]);
    const bool reset = changedUser.forceReset || static_cast<int>(user[1]) != 0;
    if (reset) {
        const std::string password = random_string(20);
        const std::string hash = makeHash(password, salt);
        if (hash.size() != 128) return 1;
        session.sql("UPDATE Users SET Login = ?, Nachname = ?, Vorname = ?, Email = ?, Rolle = ?, hash = ?, forceResetPass = 1 WHERE id = ?")
            .bind(changedUser.login).bind(changedUser.lastName).bind(changedUser.firstName).bind(changedUser.email).bind(changedUser.role).bind(hash).bind(changedUser.id).execute();
        std::string mailError;
        if (!mailer::sendPasswordReset(m_mailConf, changedUser.email, password, &mailError)) return 1;
    } else {
        session.sql("UPDATE Users SET Login = ?, Nachname = ?, Vorname = ?, Email = ?, Rolle = ? WHERE id = ?")
            .bind(changedUser.login).bind(changedUser.lastName).bind(changedUser.firstName).bind(changedUser.email).bind(changedUser.role).bind(changedUser.id).execute();
    }
    tx.commit();
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::getRechteKategorien(const int64_t id, std::vector<db::raw::RechteKategorie> & rechtekategorienList)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        try {
            mysqlx::Session session = m_dbClient.getSession();
            mysqlx::SqlStatement query = session.sql(
                "SELECT Rolle, Kategorie "
                "FROM RechteKategorie "
            );
            mysqlx::SqlResult result = query.execute();

            for(mysqlx::Row row : result) {
                db::raw::RechteKategorie nextEintrag;

                nextEintrag.role = (int32_t)row[0];
                nextEintrag.kategorie = row[1];

                rechtekategorienList.push_back(nextEintrag);
            }

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::getRechteGruppe(const int64_t id, std::vector<db::raw::RechteGruppe> & rechtegruppeList)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        try {
            mysqlx::Session session = m_dbClient.getSession();
            mysqlx::SqlStatement query = session.sql(
                "SELECT Rolle, Gruppe "
                "FROM RechteGruppe "
            );
            mysqlx::SqlResult result = query.execute();

            for(mysqlx::Row row : result) {
                db::raw::RechteGruppe nextEintrag;

                nextEintrag.role = (int32_t)row[0];
                nextEintrag.gruppe = row[1];

                rechtegruppeList.push_back(nextEintrag);
            }

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::setRechte(const int64_t id, const uint64_t rolle, std::vector<uint64_t>& kategorien, std::vector<uint64_t>& gruppen)
try
{
    const int rc = checkGF(id);
    if (rc != 0) return rc;
    if (rolle == 0) return 2;
    mysqlx::Session session = m_dbClient.getSession();
    Transaction tx(session);
    if (!session.sql("SELECT id FROM Rollen WHERE id = ? FOR UPDATE").bind(rolle).execute().fetchOne()) return 2;
    session.sql("DELETE FROM RechteGruppe WHERE Rolle = ?").bind(rolle).execute();
    session.sql("DELETE FROM RechteKategorie WHERE Rolle = ?").bind(rolle).execute();
    for (const auto group : std::set<uint64_t>(gruppen.begin(), gruppen.end()))
        session.sql("INSERT INTO RechteGruppe (Rolle, Gruppe) VALUES (?, ?)").bind(rolle).bind(group).execute();
    for (const auto category : std::set<uint64_t>(kategorien.begin(), kategorien.end()))
        session.sql("INSERT INTO RechteKategorie (Rolle, Kategorie) VALUES (?, ?)").bind(rolle).bind(category).execute();
    tx.commit();
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}



int DatabaseOperator::changeRolle(const int64_t id, const db::raw::Rolle& rol)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        // Treat missing records and invalid names as domain failures, not success.
        if (rol.id == 0 || rol.rolle .find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Rollen WHERE Rolle = ? AND id <> ?").bind(rol.rolle).bind(rol.id).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "UPDATE Rollen "
                "SET Rolle = ? "
                "WHERE id = ? "
            );
            auto result = query.bind(rol.rolle).bind(rol.id).execute();
            if (result.getAffectedItemsCount() != 0) return 0;
            return session.sql("SELECT id FROM Rollen WHERE id = ?").bind(rol.id).execute().fetchOne() ? 0 : 2;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::changeKategorie(const int64_t id, const db::raw::Kategorie& kat)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        // Treat missing records and invalid names as domain failures, not success.
        if (kat.id == 0 || kat.name .find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Kategorie WHERE Name = ? AND id <> ?").bind(kat.name).bind(kat.id).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "UPDATE Kategorie "
                "SET Name = ? "
                "WHERE id = ? "
            );
            auto result = query.bind(kat.name).bind(kat.id).execute();
            if (result.getAffectedItemsCount() != 0) return 0;
            return session.sql("SELECT id FROM Kategorie WHERE id = ?").bind(kat.id).execute().fetchOne() ? 0 : 2;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::changeGruppe(const int64_t id, const db::raw::Gruppe& grup)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        // Treat missing records and invalid names as domain failures, not success.
        if (grup.id == 0 || grup.name .find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Gruppe WHERE Name = ? AND id <> ?").bind(grup.name).bind(grup.id).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "UPDATE Gruppe "
                "SET Name = ? "
                "WHERE id = ? "
            );
            auto result = query.bind(grup.name).bind(grup.id).execute();
            if (result.getAffectedItemsCount() != 0) return 0;
            return session.sql("SELECT id FROM Gruppe WHERE id = ?").bind(grup.id).execute().fetchOne() ? 0 : 2;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::deleteRolle(const int64_t id, const db::raw::Rolle& rolle)
try
{
    int rc = checkGF(id); if (rc != 0) return rc;
    mysqlx::Session session = m_dbClient.getSession();
    auto used = session.sql("SELECT COUNT(*) FROM Users WHERE Rolle = ?").bind(rolle.id).execute().fetchOne();
    if (!used || static_cast<int64_t>(used[0]) != 0) return 2;
    auto result = session.sql("DELETE FROM Rollen WHERE id = ?").bind(rolle.id).execute();
    return result.getAffectedItemsCount() == 1 ? 0 : 2;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}



int DatabaseOperator::deleteKategorie(const int64_t id, const db::raw::Kategorie& kategorie)
try
{
    int rc = checkGF(id); if (rc != 0) return rc;
    mysqlx::Session session = m_dbClient.getSession();
    auto used = session.sql("SELECT COUNT(*) FROM Kategorienzuordnung WHERE Kategorie = ?").bind(kategorie.id).execute().fetchOne();
    if (!used || static_cast<int64_t>(used[0]) != 0) return 2;
    auto result = session.sql("DELETE FROM Kategorie WHERE id = ?").bind(kategorie.id).execute();
    return result.getAffectedItemsCount() == 1 ? 0 : 2;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}



int DatabaseOperator::deleteGruppe(const int64_t id, const db::raw::Gruppe& grup)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        try {
            mysqlx::Session session = m_dbClient.getSession();
            mysqlx::SqlStatement query = session.sql(
                "SELECT COUNT(*) "
                "FROM Dokumente "
                "WHERE Gruppe = ? "
            );
            mysqlx::SqlResult result = query.bind(grup.id).execute();
            
            
            mysqlx::Row row = result.fetchOne();

            if(row != 0 && static_cast<int>(row[0]) != 0){
                std::cerr << "Gruppe can not be deleted, still in use" << std::endl;
                return 2;
            }

            query = session.sql(
                "DELETE FROM Gruppe "
                "WHERE id = ? "
            );
            auto deleted = query.bind(grup.id).execute();
            return deleted.getAffectedItemsCount() == 1 ? 0 : 2;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::setNewRolle(const int64_t id, const db::raw::Rolle& rol)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        if (rol.rolle.find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Rollen WHERE Rolle = ?").bind(rol.rolle).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "INSERT INTO Rollen (Rolle) "
                "VALUES(?) "
            );
            mysqlx::SqlResult result = query.bind(rol.rolle).execute();

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::setNewKategorie(const int64_t id, const db::raw::Kategorie& kat)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        if (kat.name.find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Kategorie WHERE Name = ?").bind(kat.name).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "INSERT INTO Kategorie (Name) "
                "VALUES(?) "
            );
            mysqlx::SqlResult result = query.bind(kat.name).execute();

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::setNewGruppe(const int64_t id, const db::raw::Gruppe& grup)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        if (grup.name.find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Gruppe WHERE Name = ?").bind(grup.name).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "INSERT INTO Gruppe (Name) "
                "VALUES(?) "
            );
            mysqlx::SqlResult result = query.bind(grup.name).execute();

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::changeTaetigkeit(const int64_t id, const db::raw::Taetigkeit& taet)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        // Treat missing records and invalid names as domain failures, not success.
        if (taet.id == 0 || taet.name .find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Taetigkeit WHERE Name = ? AND id <> ?").bind(taet.name).bind(taet.id).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "UPDATE Taetigkeit "
                "SET Name = ? "
                ", Abrechenbar = ? "
                ", Buchbar = ? "
                "WHERE id = ? "
            );
            mysqlx::SqlResult result = query.bind(taet.name).bind((taet.abrechenbar)?1:0).bind((taet.buchbar)?1:0).bind(taet.id).execute();

            if (result.getAffectedItemsCount() != 0) return 0;
            return session.sql("SELECT id FROM Taetigkeit WHERE id = ?").bind(taet.id).execute().fetchOne() ? 0 : 2;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::deleteTaetigkeit(const int64_t id, const db::raw::Taetigkeit& taet)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        try {
            mysqlx::Session session = m_dbClient.getSession();
            mysqlx::SqlStatement query = session.sql(
                "SELECT COUNT(*) "
                "FROM Zeiterfassung "
                "WHERE Taetigkeit = ? "
            );
            mysqlx::SqlResult result = query.bind(taet.id).execute();

            
            mysqlx::Row row = result.fetchOne();

            if(row != 0 && static_cast<int>(row[0]) != 0){
                std::cerr << "Taetigkeit can not be deleted, still in use" << std::endl;
                return 2;
            }

            query = session.sql(
                "DELETE FROM Taetigkeit "
                "WHERE id = ? "
            );
            auto deleted = query.bind(taet.id).execute();
            return deleted.getAffectedItemsCount() == 1 ? 0 : 2;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::setNewTaetigkeit(const int64_t id, const db::raw::Taetigkeit& taet)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        if (taet.name.find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Taetigkeit WHERE Name = ?").bind(taet.name).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "INSERT INTO Taetigkeit (Name, Abrechenbar, Buchbar) "
                "VALUES(?, ?, ?) "
            );
            mysqlx::SqlResult result = query.bind(taet.name).bind((taet.abrechenbar)?1:0).bind((taet.buchbar)?1:0).execute();

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::getBetreuungen(const int64_t id, bool aktiv, std::vector<db::raw::Betreuung>& betreuungenList)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        try {
            mysqlx::Session session = m_dbClient.getSession();
            mysqlx::SqlResult result;
            if(aktiv){
                mysqlx::SqlStatement query = session.sql(
                    "SELECT id, Betreuer, Klient, DATE_FORMAT(GueltigVon,'%Y-%m-%d'), DATE_FORMAT(GueltigBis,'%Y-%m-%d'), Stundensatz, Wochenstunden "
                    "FROM Betreuungen "
                    "WHERE NOW() BETWEEN GueltigVon AND GueltigBis "
                );
                result = query.execute();
            }else{
                mysqlx::SqlStatement query = session.sql(
                    "SELECT id, Betreuer, Klient, DATE_FORMAT(GueltigVon,'%Y-%m-%d'), DATE_FORMAT(GueltigBis,'%Y-%m-%d'), Stundensatz, Wochenstunden "
                    "FROM Betreuungen "
                );
                result = query.execute();
            }

            for(mysqlx::Row row : result) {
                db::raw::Betreuung nextEintrag;

                nextEintrag.id = row[0];
                nextEintrag.betreuer = row[1];
                nextEintrag.klient = row[2];
                nextEintrag.gueltigVon = std::string(row[3]);
                nextEintrag.gueltigBis = std::string(row[4]);
                nextEintrag.stundensatz = row[5];
                nextEintrag.wochenstunden = row[6];

                betreuungenList.push_back(nextEintrag);
            }

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::endBetreuung(const int64_t id, const int64_t idBetreuung)
try
{
    const int rc = checkGF(id);
    if (rc != 0) return rc;
    if (idBetreuung <= 0) return 2;
    mysqlx::Session session = m_dbClient.getSession();
    // Serialize with time-entry/care creation, which also locks the employee first.
    // The initial read is outside the transaction so a later history read does
    // not use a snapshot taken before waiting for the employee lock.
    auto owner = session.sql("SELECT Betreuer FROM Betreuungen WHERE id = ?").bind(idBetreuung).execute().fetchOne();
    if (!owner) return 2;
    const int64_t employeeId = owner[0];
    Transaction tx(session);
    if (!session.sql("SELECT id FROM Users WHERE id = ? FOR UPDATE").bind(employeeId).execute().fetchOne()) return 2;
    auto row = session.sql("SELECT (GueltigVon > DATE_SUB(CURDATE(), INTERVAL 1 DAY)), "
        "(SELECT COUNT(*) FROM Zeiterfassung z WHERE z.Betreuung = b.id), "
        "(GueltigBis >= CURDATE()), "
        "(SELECT COUNT(*) FROM Zeiterfassung z WHERE z.Betreuung = b.id AND z.Bis > CURDATE()) "
        "FROM Betreuungen b WHERE b.id = ? AND b.Betreuer = ? FOR UPDATE")
        .bind(idBetreuung).bind(employeeId).execute().fetchOne();
    if (!row || static_cast<int>(row[2]) == 0) return 2;
    // Ending yesterday would put today's/future time entries outside the care
    // period; reject rather than silently making recorded history invalid.
    if (static_cast<int64_t>(row[3]) != 0) return 2;
    if (static_cast<int>(row[0]) != 0) {
        // A future/today-only period cannot end yesterday. Remove it only if
        // that would not discard recorded history.
        if (static_cast<int64_t>(row[1]) != 0) return 2;
        session.sql("DELETE FROM Betreuungen WHERE id = ?").bind(idBetreuung).execute();
    } else {
        session.sql("UPDATE Betreuungen SET GueltigBis = DATE_SUB(CURDATE(), INTERVAL 1 DAY) WHERE id = ?").bind(idBetreuung).execute();
    }
    tx.commit();
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


// Reject overlaps instead of silently truncating existing care periods. This
// avoids altering historical time entries; an administrator can end a period first.
int DatabaseOperator::setNewBetreuung(const int64_t id, const db::raw::Betreuung& betreuung)
try
{
    int rc = checkGF(id); if (rc != 0) return rc;
    if (betreuung.betreuer == 0 || betreuung.klient == 0 || betreuung.gueltigVon > betreuung.gueltigBis) return 2;
    mysqlx::Session session = m_dbClient.getSession();
    Transaction tx(session);
    if (!session.sql("SELECT id FROM Users WHERE id = ? FOR UPDATE").bind(betreuung.betreuer).execute().fetchOne()) return 2;
    auto conflict = session.sql("SELECT id FROM Betreuungen WHERE Betreuer = ? AND Klient = ? AND GueltigVon <= STR_TO_DATE(?,'%Y-%m-%d') AND GueltigBis >= STR_TO_DATE(?,'%Y-%m-%d') LIMIT 1")
        .bind(betreuung.betreuer).bind(betreuung.klient).bind(betreuung.gueltigBis).bind(betreuung.gueltigVon).execute();
    if (conflict.fetchOne()) return 2;
    session.sql("INSERT INTO Betreuungen (Betreuer, Klient, GueltigVon, GueltigBis, Stundensatz, Wochenstunden) VALUES (?, ?, STR_TO_DATE(?,'%Y-%m-%d'), STR_TO_DATE(?,'%Y-%m-%d'), ?, ?)")
        .bind(betreuung.betreuer).bind(betreuung.klient).bind(betreuung.gueltigVon).bind(betreuung.gueltigBis).bind(betreuung.stundensatz).bind(betreuung.wochenstunden).execute();
    tx.commit();
    return 0;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}



int DatabaseOperator::getAuswertungBetreuung(const int64_t id, const int64_t betreuungId, const std::string monat, const bool excludeNA, std::vector<db::resolved::Zeiterfassung>& zeiteintraege)
try
{
    
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{
        mysqlx::Session session = m_dbClient.getSession();
        try {

            mysqlx::SqlResult result;

            std::string excludeNAString = (excludeNA)? "AND t.Abrechenbar = true " : "";

            mysqlx::SqlStatement query = session.sql(
                "SELECT u.Vorname, u.Nachname, t.Name, k.Vorname, k.Nachname, DATE_FORMAT(z.von,'%Y-%m-%d-%H-%i'), DATE_FORMAT(z.bis,'%Y-%m-%d-%H-%i'), z.Beschreibung, t.Abrechenbar "
                "FROM Zeiterfassung z "
                "JOIN Betreuungen b "
                "ON z.Betreuung = b.id "
                "JOIN Taetigkeit t "
                "ON t.id = z.Taetigkeit "
                "JOIN Users u "
                "ON u.id = b.Betreuer "
                "JOIN Klienten k "
                "ON k.id = b.Klient "
                "WHERE b.id = ? "
                // Half-open month: an entry at midnight on the 1st belongs to the next month.
                "AND z.Von >= STR_TO_DATE(?,'%Y-%m-%d') AND z.Von < STR_TO_DATE(?,'%Y-%m-%d') + INTERVAL 1 MONTH "
                + excludeNAString
            );

            result = query.bind(betreuungId).bind(monat).bind(monat).execute();

            for(mysqlx::Row row : result) {
                db::resolved::Zeiterfassung nextEintrag;

                nextEintrag.betreuerName = std::string(row[0]) + " " + std::string(row[1]);
                nextEintrag.taetigkeitName = std::string(row[2]);
                nextEintrag.klientName = std::string(row[3]) + " " + std::string(row[4]);
                nextEintrag.von = std::string(row[5]);
                nextEintrag.bis = std::string(row[6]);
                nextEintrag.beschreibung = std::string(row[7]);
                nextEintrag.istAbrechenbar = static_cast<int>(row[8]);


                zeiteintraege.push_back(nextEintrag);
            }

            return 0;
        }
        catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::getAuswertungBetreuer(const int64_t id, const int64_t betreuerId, const std::string monat, const bool excludeNA, std::vector<db::resolved::Zeiterfassung>& zeiteintraege)
try
{
    
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{
        mysqlx::Session session = m_dbClient.getSession();
        try {

            mysqlx::SqlResult result;

            std::string excludeNAString = (excludeNA)? "AND t.Abrechenbar = true " : "";

            mysqlx::SqlStatement query = session.sql(
                "SELECT u.Vorname, u.Nachname, t.Name, k.Vorname, k.Nachname, DATE_FORMAT(z.von,'%Y-%m-%d-%H-%i'), DATE_FORMAT(z.bis,'%Y-%m-%d-%H-%i'), z.Beschreibung, t.Abrechenbar "
                "FROM Zeiterfassung z "
                "JOIN Betreuungen b "
                "ON z.Betreuung = b.id "
                "JOIN Taetigkeit t "
                "ON t.id = z.Taetigkeit "
                "JOIN Users u "
                "ON u.id = b.Betreuer "
                "JOIN Klienten k "
                "ON k.id = b.Klient "
                "WHERE u.id = ? "
                // Half-open month: an entry at midnight on the 1st belongs to the next month.
                "AND z.Von >= STR_TO_DATE(?,'%Y-%m-%d') AND z.Von < STR_TO_DATE(?,'%Y-%m-%d') + INTERVAL 1 MONTH "
                + excludeNAString
            );

            result = query.bind(betreuerId).bind(monat).bind(monat).execute();

            for(mysqlx::Row row : result) {
                db::resolved::Zeiterfassung nextEintrag;

                nextEintrag.betreuerName = std::string(row[0]) + " " + std::string(row[1]);
                nextEintrag.taetigkeitName = std::string(row[2]);
                nextEintrag.klientName = std::string(row[3]) + " " + std::string(row[4]);
                nextEintrag.von = std::string(row[5]);
                nextEintrag.bis = std::string(row[6]);
                nextEintrag.beschreibung = std::string(row[7]);
                nextEintrag.istAbrechenbar = static_cast<int>(row[8]);


                zeiteintraege.push_back(nextEintrag);
            }

            return 0;
        }
        catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::getAuswertungKlient(const int64_t id, const int64_t klientId, const std::string monat, const bool excludeNA, std::vector<db::resolved::Zeiterfassung>& zeiteintraege)
try
{
    
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{
        mysqlx::Session session = m_dbClient.getSession();
        try {

            mysqlx::SqlResult result;

            std::string excludeNAString = (excludeNA)? "AND t.Abrechenbar = true " : "";

            mysqlx::SqlStatement query = session.sql(
                "SELECT u.Vorname, u.Nachname, t.Name, k.Vorname, k.Nachname, DATE_FORMAT(z.von,'%Y-%m-%d-%H-%i'), DATE_FORMAT(z.bis,'%Y-%m-%d-%H-%i'), z.Beschreibung, t.Abrechenbar "
                "FROM Zeiterfassung z "
                "JOIN Betreuungen b "
                "ON z.Betreuung = b.id "
                "JOIN Taetigkeit t "
                "ON t.id = z.Taetigkeit "
                "JOIN Users u "
                "ON u.id = b.Betreuer "
                "JOIN Klienten k "
                "ON k.id = b.Klient "
                "WHERE k.id = ? "
                // Half-open month: an entry at midnight on the 1st belongs to the next month.
                "AND z.Von >= STR_TO_DATE(?,'%Y-%m-%d') AND z.Von < STR_TO_DATE(?,'%Y-%m-%d') + INTERVAL 1 MONTH "
                + excludeNAString
            );

            result = query.bind(klientId).bind(monat).bind(monat).execute();

            for(mysqlx::Row row : result) {
                db::resolved::Zeiterfassung nextEintrag;

                nextEintrag.betreuerName = std::string(row[0]) + " " + std::string(row[1]);
                nextEintrag.taetigkeitName = std::string(row[2]);
                nextEintrag.klientName = std::string(row[3]) + " " + std::string(row[4]);
                nextEintrag.von = std::string(row[5]);
                nextEintrag.bis = std::string(row[6]);
                nextEintrag.beschreibung = std::string(row[7]);
                nextEintrag.istAbrechenbar = static_cast<int>(row[8]);

                zeiteintraege.push_back(nextEintrag);
            }

            return 0;
        }
        catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


int DatabaseOperator::changeKlient(const int64_t id, const db::raw::Klient& klient)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        // ID zero is reserved for common documents and must not be renamed.
        if (klient.id == 0 || klient.firstName.find_first_not_of(" \t\r\n") == std::string::npos ||
            klient.lastName.find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Klienten WHERE Vorname = ? AND Nachname = ? AND id <> ?")
                .bind(klient.firstName).bind(klient.lastName).bind(klient.id).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "UPDATE Klienten "
                "SET Nachname = ? "
                ", Vorname = ? "
                "WHERE id = ? "
            );
            mysqlx::SqlResult result = query.bind(klient.lastName).bind(klient.firstName).bind(klient.id).execute();

            if (result.getAffectedItemsCount() != 0) return 0;
            return session.sql("SELECT id FROM Klienten WHERE id = ?").bind(klient.id).execute().fetchOne() ? 0 : 2;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}


// Preserve history and documents rather than cascading away linked data.
int DatabaseOperator::deleteKlient(const int64_t id, const db::raw::Klient& klient)
try
{
    int rc = checkGF(id); if (rc != 0) return rc;
    if (klient.id == 0) return 2;
    mysqlx::Session session = m_dbClient.getSession();
    auto used = session.sql("SELECT (SELECT COUNT(*) FROM Betreuungen WHERE Klient = ?) + (SELECT COUNT(*) FROM Dokumente WHERE Klient = ?)")
        .bind(klient.id).bind(klient.id).execute().fetchOne();
    if (!used || static_cast<int64_t>(used[0]) != 0) return 2;
    auto result = session.sql("DELETE FROM Klienten WHERE id = ?").bind(klient.id).execute();
    return result.getAffectedItemsCount() == 1 ? 0 : 2;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}



int DatabaseOperator::setNewKlient(const int64_t id, const db::raw::Klient& klient)
try
{
    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        if (klient.firstName.find_first_not_of(" \t\r\n") == std::string::npos ||
            klient.lastName.find_first_not_of(" \t\r\n") == std::string::npos) return 2;
        try {
            mysqlx::Session session = m_dbClient.getSession();
            if (session.sql("SELECT id FROM Klienten WHERE Vorname = ? AND Nachname = ?")
                .bind(klient.firstName).bind(klient.lastName).execute().fetchOne()) return 2;
            mysqlx::SqlStatement query = session.sql(
                "INSERT INTO Klienten (Nachname, Vorname) "
                "VALUES(?, ?) "
            );
            mysqlx::SqlResult result = query.bind(klient.lastName).bind(klient.firstName).execute();

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::getKlientenList(const int64_t id, std::vector<db::raw::Klient> & klientList)
try
{

    int rc = checkGF(id);
    if(rc != 0){
            return rc;
    }else{

        try {
            mysqlx::Session session = m_dbClient.getSession();
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Nachname, Vorname "
                "FROM Klienten "
                "WHERE id != 0 "
            );
            mysqlx::SqlResult result = query.execute();

            for(mysqlx::Row row : result) {
                db::raw::Klient nextEintrag;

                nextEintrag.id = static_cast<uint64_t>(row[0]);
                nextEintrag.lastName = std::string(row[1]);
                nextEintrag.firstName = std::string(row[2]);

                klientList.push_back(nextEintrag);
            }

            return 0;

        }catch (const mysqlx::Error &err) {
            std::cerr << "Database Query Error: " << err.what() << std::endl;
            return 1;
        }
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
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
try
{
    mysqlx::Session session = m_dbClient.getSession();

    try {
        mysqlx::SqlResult result;
        if(login.length() > 0){
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Login, Nachname, Vorname, Email, salt, hash, Rolle, forceResetPass "
                "FROM Users WHERE Login = ?"
            );
            result = query.bind(login).execute();

        }else{
            mysqlx::SqlStatement query = session.sql(
                "SELECT id, Login, Nachname, Vorname, Email, salt, hash, Rolle, forceResetPass "
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
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

std::string DatabaseOperator::random_string(std::size_t length)
{
    std::string buffer(length, '\0');

    if (RAND_bytes(reinterpret_cast<unsigned char*>(buffer.data()),
                   static_cast<int>(length)) != 1) {
        throw std::runtime_error("RAND_bytes failed");
    }
    constexpr char hex[] = "0123456789abcdef";
    std::string out;
    out.reserve(buffer.size() * 2);
    for (unsigned char b : buffer) {
        out += hex[b >> 4];
        out += hex[b & 0x0F];
    }
    return out;
}

int DatabaseOperator::resetPasswordAndMail(const uint64_t userId)try
{
    mysqlx::Session session = m_dbClient.getSession();
    db::raw::User user;
    if (selectUser("", userId, user) != 0) return 1;

    std::string newPass = random_string(20);

    try {

        std::string es;
        mysqlx::SqlResult result;
        

        if(mailer::sendPasswordReset(m_mailConf, user.email, newPass, &es)){

            mysqlx::SqlStatement query = session.sql(
                "UPDATE Users "
                "SET hash = ? "
                "WHERE id = ? "
            );
            result = query.bind(makeHash(newPass, user.salt)).bind(userId).execute();

            return 0;
        }else{
            std::cerr << "Mailing Error" << std::endl;
            return -1;
        }
    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }
    return 2;

} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}

int DatabaseOperator::checkGF(const uint64_t id)
try
{
    mysqlx::Session session = m_dbClient.getSession();
    int32_t role = 0;
    try {
        mysqlx::SqlResult result;

        mysqlx::SqlStatement query = session.sql(
            "SELECT Rolle "
            "FROM Users "
            "WHERE id = ? "
        );
        result = query.bind(id).execute();


        mysqlx::Row row = result.fetchOne();

        if (!row) {
            std::cerr << "User not found" << std::endl;
            return 2;
        }
        
        role = row[0];

        if(role != 1){
            std::cerr << "User not authorized" << std::endl;
            return 3;
        }else{
            return 0;
        }
    }catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }

    return -1;
} catch (const std::exception& error) {
    std::cerr << "Database operation failed: " << error.what() << std::endl;
    return 1;
} catch (...) {
    std::cerr << "Database operation failed (unknown error)" << std::endl;
    return 1;
}
