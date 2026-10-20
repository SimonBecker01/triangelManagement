
add_executable(triangelbackend main.cpp utils.cpp jwt_auth.cpp database_ops.cpp serviceimplement.cpp mailer.cpp)
set_target_properties(triangelbackend PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "/opt/triangelservice/"
    INSTALL_RPATH "$ORIGIN/lib"
    BUILD_WITH_INSTALL_RPATH TRUE
)

target_include_directories(triangelbackend PRIVATE ${CMAKE_SOURCE_DIR}/include ${MYSQL_INCLUDE})

target_link_libraries(triangelbackend PRIVATE
    triangel_proto
    gRPC::grpc++
    protobuf::libprotobuf
    ${MYSQL_LIB}
    OpenSSL::SSL
    OpenSSL::Crypto
)
