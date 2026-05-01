cmake_minimum_required(VERSION 3.0)
project(poly_acc)

set(CMAKE_C_STANDARD 11)

include_directories(
        $ENV{UXLIDEC}/src/gems/actors/common
        $ENV{UXLIDEC}/src/gems/actors/basic
        $ENV{UXLIDEC}/src/gems/edges/basic
        $ENV{UXLIDEC}/src/gems/graph/common
        $ENV{UXLIDEC}/src/tools/runtime
)

add_subdirectory(src/c)
add_subdirectory(test/test_c/util)
