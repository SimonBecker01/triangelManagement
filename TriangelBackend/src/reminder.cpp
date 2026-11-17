#include <iostream>
#include <mysqlx/xdevapi.h>
#include "mailer.hpp"
#include "utils.hpp"


int main() try {

    mysqlx::Client dbClient(utils::load_credential("db_cred"), mysqlx::ClientOption::POOL_MAX_SIZE, 20);
    mailer::SmtpConfig mailConf;

    

    mailer::init();
    // A missing mail configuration must not crash read-only services, but
    // mail-dependent operations will return an error instead of pretending success.
    std::string mailError;
    if (!mailer::SmtpConfig::load(mailConf, &mailError))
        std::cerr << "SMTP is unavailable: " << mailError << std::endl;
    
    

    mysqlx::Session session = dbClient.getSession();

    
    try {
        if(1== 0){
        mysqlx::SqlResult result;
        mysqlx::SqlStatement query = session.sql(
            "SELECT u.Email, u.Login "
            "FROM Users u "
            "JOIN Betreuungen b "
            "ON u.id = b.Betreuer "
            "WHERE u.Rolle != 1 "
            "AND u.Rolle != 99 "
            "AND NOT EXISTS(SELECT z.* "
                "FROM Zeiterfassung z "
                "WHERE z.Betreuung = b.id "
                "AND z.Von BETWEEN CAST(DATE_FORMAT(NOW() ,'%Y-%m-01') as DATE) AND LAST_DAY(NOW())) "
        );
        result = query.execute();

        
        for(mysqlx::Row row : result) {
            std::string ec;
            mailer::sendWorkReminder(mailConf, std::string(row[0]), &ec);
            if(ec.length() > 0) std::cerr << "Could not send mail to " << std::string(row[1]) << ": " << ec << std::endl;
        }
    }

    }
    catch (const mysqlx::Error &err) {
        std::cerr << "Database Query Error: " << err.what() << std::endl;
        return 1;
    }
    
    try {
        mysqlx::SqlResult result;
        mysqlx::SqlStatement query = session.sql(
            "SELECT u.Vorname, u.Nachname, k.Vorname, k.Nachname, DATE_FORMAT(b.GueltigBis,'%Y-%m-%d') "
            "FROM Betreuungen b "
            "JOIN Users u "
            "ON u.id = b.Betreuer "
            "JOIN Klienten k "
            "ON k.id = b.Klient "
            "WHERE b.GueltigBis < DATE_ADD(NOW(), INTERVAL 60 DAY) "
            "AND NOT EXISTS(SELECT bi.* "
                "FROM Betreuungen bi "
                "WHERE b.Betreuer = bi.Betreuer "
                "AND b.Klient = bi.Klient "
                "AND b.GueltigBis < bi.GueltigBis) "
        );

        result = query.execute();

        std::string listeAblauf;

        for(mysqlx::Row row : result) {
            listeAblauf += '\n';
            listeAblauf.append(std::string(row[0])).append(" ").append(std::string(row[1])).append(" betreut ").append(std::string(row[2])).append(" ").append(std::string(row[3])).append(" bis zum ").append(std::string(row[4]));
        }
        
        if(listeAblauf.length() > 0){
            query = session.sql(
                "SELECT u.Email, u.Login "
                "FROM Users u "
                "WHERE u.Rolle = 1 "
            );

            result = query.execute();
            
            for(mysqlx::Row row : result) {
                std::string ec;
                mailer::sendBetreuungReminder(mailConf, std::string(row[0]), listeAblauf, &ec);
                if(ec.length() > 0) std::cerr << "Could not send mail to " << std::string(row[1]) << ": " << ec << std::endl;
            }
        }
        

    try { dbClient.close(); }
    catch (const std::exception& e) { std::cerr << "Closing database pool failed: " << e.what() << std::endl; }
    catch (...) { std::cerr << "Closing database pool failed" << std::endl; }
    mailer::cleanup();
    return 0;
    } catch (const std::exception& error) {
        std::cerr << "Database operation failed: " << error.what() << std::endl;
        return 1;
    } catch (...) {
        std::cerr << "Database operation failed (unknown error)" << std::endl;
        return 1;
    }
}
catch (const mysqlx::Error &err) {
    std::cerr << "Database Query Error: " << err.what() << std::endl;
    return 1;
}
        
