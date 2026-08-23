
add_executable(triangelbackend main.cpp jwt_auth.cpp database_mgr.cpp database_ops.cpp serviceimplement.cpp)

target_include_directories(triangelbackend PRIVATE ${CMAKE_SOURCE_DIR}/include ${MYSQL_INCLUDE})

target_link_libraries(triangelbackend PRIVATE
    triangel_proto
    gRPC::grpc++
    protobuf::libprotobuf
    ${MYSQL_LIB}
    OpenSSL::SSL
    OpenSSL::Crypto
)
