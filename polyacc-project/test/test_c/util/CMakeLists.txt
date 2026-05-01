# Add LIDE include paths
include_directories(
    "$ENV{UXLIDEC}/src/gems/actors/common"
    "$ENV{UXLIDEC}/src/gems/actors/basic"
    "$ENV{UXLIDEC}/src/gems/edges/basic"
    "$ENV{UXLIDEC}/src/tools/runtime"
)

# Also add our actor's header directory
include_directories(
    ${PROJECT_SOURCE_DIR}/src/c
)

# Create the executable for our test driver
add_executable(driver.exe
    driver.c
)

# Link the executable against:
# 1. Our custom project library ('polyacc_actor_lib') from src/c
# 2. The standard LIDE libraries (needed by driver.c)
target_link_libraries(driver.exe
    polyacc_actor_lib
    "$ENV{LIDEGEN}/liblide_c_actors_basic.a"
    "$ENV{LIDEGEN}/liblide_c_edges_basic.a"
    "$ENV{LIDEGEN}/liblide_c_runtime.a"
)

INSTALL(TARGETS driver.exe DESTINATION ${PROJECT_SOURCE_DIR}/bin/c)

