cmake_minimum_required(VERSION 3.15)
project(triangelbackend VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(ABSL_PROPAGATE_CXX_STD ON)

find_package(Protobuf CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(CURL REQUIRED)

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
    GRPC_PLUGIN_LOCATION
    gRPC::grpc_cpp_plugin
    IMPORTED_LOCATION_RELEASE
)
if(NOT GRPC_PLUGIN_LOCATION)
    get_target_property(
        GRPC_PLUGIN_LOCATION
        gRPC::grpc_cpp_plugin
        IMPORTED_LOCATION_NOCONFIG
    )
endif()

if(GRPC_PLUGIN_LOCATION)
    # <prefix>/bin/grpc_cpp_plugin  ->  <prefix>/lib
    get_filename_component(_grpc_plugin_bin_dir "${GRPC_PLUGIN_LOCATION}" DIRECTORY)
    get_filename_component(GRPC_LIB_DIR "${_grpc_plugin_bin_dir}/../lib" ABSOLUTE)
else()
    get_filename_component(GRPC_LIB_DIR "$ENV{HOME}/.local/grpc-openssl/lib" ABSOLUTE)
endif()

if(NOT EXISTS "${GRPC_LIB_DIR}/libgrpc_plugin_support.so")
    message(
        FATAL_ERROR
        "Could not locate libgrpc_plugin_support.so under '${GRPC_LIB_DIR}'.\n"
        "Set -DGRPC_LIB_DIR=<path to the lib dir of your gRPC install>."
    )
endif()

set(GRPC_PLUGIN_LIBRARY_PATH "LD_LIBRARY_PATH=${GRPC_LIB_DIR}")
if(DEFINED ENV{LD_LIBRARY_PATH} AND NOT "$ENV{LD_LIBRARY_PATH}" STREQUAL "")
    set(
        GRPC_PLUGIN_LIBRARY_PATH
        "${GRPC_PLUGIN_LIBRARY_PATH}:$ENV{LD_LIBRARY_PATH}"
    )
endif()

message(STATUS "gRPC plugin library dir: ${GRPC_LIB_DIR}")
message(STATUS "protoc will be run with:  ${GRPC_PLUGIN_LIBRARY_PATH}")

set(PROTOBUF_LIB_DIR "")
if(TARGET protobuf::libprotobuf)
    get_target_property(
        _protobuf_lib_location
        protobuf::libprotobuf
        IMPORTED_LOCATION_RELEASE
    )
    if(NOT _protobuf_lib_location)
        get_target_property(
            _protobuf_lib_location
            protobuf::libprotobuf
            IMPORTED_LOCATION_NOCONFIG
        )
    endif()
    if(_protobuf_lib_location)
        get_filename_component(
            PROTOBUF_LIB_DIR
            "${_protobuf_lib_location}"
            DIRECTORY
        )
    endif()
endif()

set(
    TRIANGEL_EXTRA_LIB_DIRS
    ""
    CACHE STRING
    "Extra runtime library directories (e.g. if a dependency lives in its own prefix)"
)

set(_triangel_runtime_lib_dirs "${GRPC_LIB_DIR}")
if(PROTOBUF_LIB_DIR)
    list(APPEND _triangel_runtime_lib_dirs "${PROTOBUF_LIB_DIR}")
endif()
if(TRIANGEL_EXTRA_LIB_DIRS)
    list(APPEND _triangel_runtime_lib_dirs ${TRIANGEL_EXTRA_LIB_DIRS})
endif()
list(REMOVE_DUPLICATES _triangel_runtime_lib_dirs)

message(STATUS "runtime library search path: ${_triangel_runtime_lib_dirs}")

set(CMAKE_BUILD_RPATH "${_triangel_runtime_lib_dirs}")
set(CMAKE_INSTALL_RPATH "${_triangel_runtime_lib_dirs}")

add_link_options("-Wl,--disable-new-dtags")

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
    COMMAND
        ${CMAKE_COMMAND} -E env "${GRPC_PLUGIN_LIBRARY_PATH}"
        $<TARGET_FILE:protobuf::protoc>
        --proto_path=${PROTO_DIR}
        --cpp_out=${GENERATED_DIR}
        --grpc_out=${GENERATED_DIR}
        --plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>
        ${PROTO_FILE}
    DEPENDS
        ${PROTO_FILE}
    COMMENT "Generating protobuf/gRPC sources for triangel.proto"
    VERBATIM
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
        CURL::libcurl
)