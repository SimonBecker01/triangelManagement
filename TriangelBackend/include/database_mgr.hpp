#pragma once

#include <string>
#include <mysqlx/xdevapi.h>


class DatabaseManager {
public:
    DatabaseManager();
    ~DatabaseManager();
    mysqlx::Session getSession();
private:
    mysqlx::Client m_client;
};