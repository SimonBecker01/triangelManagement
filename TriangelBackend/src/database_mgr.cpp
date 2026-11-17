#include "database_mgr.hpp"
#include "utils.hpp"
#include <iostream>
#include <stdexcept>

// CHANGE: use the same systemd credential as DatabaseOperator, not a compiled-in password.
DatabaseManager::DatabaseManager()
    : m_client(utils::load_credential("db_cred"), mysqlx::ClientOption::POOL_MAX_SIZE, 20) {
}

// [CHANGE] Guard m_client.close() in destructor so exceptions never escape a destructor.
DatabaseManager::~DatabaseManager() {
    try {
        m_client.close();
    } catch (const std::exception& e) {
        std::cerr << "Error closing DatabaseManager client: " << e.what() << std::endl;
    } catch (...) {
        std::cerr << "Unknown error closing DatabaseManager client." << std::endl;
    }
}

// [CHANGE] Added error logging and exception handling when acquiring a session.
mysqlx::Session DatabaseManager::getSession() {
    try {
        return m_client.getSession();
    } catch (const mysqlx::Error& err) {
        std::cerr << "Database Session Error: " << err.what() << std::endl;
        throw;
    }
}
