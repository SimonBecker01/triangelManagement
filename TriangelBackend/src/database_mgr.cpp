#include "database_mgr.hpp"
#include <iostream>

DatabaseManager::DatabaseManager(): m_client("triangel_user:YourSecurePassword123!@127.0.0.1/Triangel", mysqlx::ClientOption::POOL_MAX_SIZE, 20){

}

DatabaseManager::~DatabaseManager(){
    m_client.close();
}


mysqlx::Session DatabaseManager::getSession() {
    return m_client.getSession();
}
