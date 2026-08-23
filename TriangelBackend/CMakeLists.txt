cmake_minimum_required(VERSION 3.15)
project(triangelbackend VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(ABSL_PROPAGATE_CXX_STD ON)

find_package(Protobuf CONFIG REQUIRED)

set(
    TRIANGEL_GRPC_DIR
    "$ENV{HOME}/.local/grpc-openssl/lib/cmake/grpc"
    CACHE PATH
    "Directory containing the gRPC CMake package"
)

set(
    gRPC_DIR
    "${TRIANGEL_GRPC_DIR}"
    CACHE PATH
    "Directory containing gRPCConfig.cmake"
    FORCE
)

find_package(gRPC CONFIG REQUIRED)

get_target_property(
    GRPC_CPP_RELEASE
    gRPC::grpc++
    IMPORTED_LOCATION_RELEASE
)

get_target_property(
    GRPC_CPP_NOCONFIG
    gRPC::grpc++
    IMPORTED_LOCATION_NOCONFIG
)

message(STATUS "gRPC++ RELEASE location: ${GRPC_CPP_RELEASE}")
message(STATUS "gRPC++ NOCONFIG location: ${GRPC_CPP_NOCONFIG}")

find_package(OpenSSL REQUIRED)
find_package(gRPC CONFIG REQUIRED)



get_target_property(GRPC_CPP_LIBRARY gRPC::grpc++ IMPORTED_LOCATION_RELEASE)

if(NOT GRPC_CPP_LIBRARY)
    get_target_property(GRPC_CPP_LIBRARY gRPC::grpc++ IMPORTED_LOCATION_NOCONFIG)
endif()

message(STATUS "Selected gRPC++ library: ${GRPC_CPP_LIBRARY}")

find_package(OpenSSL REQUIRED)

find_library(MYSQL_CPPCONN_LIB NAMES mysqlcppconnx REQUIRED)

set(MYSQL_CPPCONN_INCLUDE_DIR "/usr/include/mysql-cppconn")


set(OPENSSL_LIBS OpenSSL::SSL OpenSSL::Crypto)
set(MYSQL_LIB ${MYSQL_CPPCONN_LIB})
set(MYSQL_INCLUDE ${MYSQL_CPPCONN_INCLUDE_DIR})

add_subdirectory(src)

set(PROTO_DIR ${CMAKE_CURRENT_SOURCE_DIR}/proto)
set(PROTO_FILE ${PROTO_DIR}/triangel.proto)

set(GENERATED_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated)
file(MAKE_DIRECTORY ${GENERATED_DIR})

set(PROTO_SRCS
    ${GENERATED_DIR}/triangel.pb.cc
)

set(PROTO_HDRS
    ${GENERATED_DIR}/triangel.pb.h
)

set(GRPC_SRCS
    ${GENERATED_DIR}/triangel.grpc.pb.cc
)

set(GRPC_HDRS
    ${GENERATED_DIR}/triangel.grpc.pb.h
)

add_custom_command(
    OUTPUT
        ${PROTO_SRCS}
        ${PROTO_HDRS}
        ${GRPC_SRCS}
        ${GRPC_HDRS}
    COMMAND $<TARGET_FILE:protobuf::protoc>
    ARGS
        --proto_path=${PROTO_DIR}
        --cpp_out=${GENERATED_DIR}
        --grpc_out=${GENERATED_DIR}
        --plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>
        ${PROTO_FILE}
    DEPENDS ${PROTO_FILE}
)

add_library(triangel_proto
    ${PROTO_SRCS}
    ${PROTO_HDRS}
    ${GRPC_SRCS}
    ${GRPC_HDRS}
)

target_include_directories(triangel_proto
    PUBLIC
        ${GENERATED_DIR}
)

target_link_libraries(triangel_proto
    PUBLIC
        protobuf::libprotobuf
        gRPC::grpc++
)
