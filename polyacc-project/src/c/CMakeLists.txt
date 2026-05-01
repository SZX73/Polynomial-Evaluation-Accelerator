include_directories(
    "$ENV{UXLIDEC}/src/gems/actors/common"
    "$ENV{UXLIDEC}/src/gems/actors/basic"
    "$ENV{UXLIDEC}/src/gems/edges/basic"
    "$ENV{UXLIDEC}/src/gems/graph/common"
    "$ENV{UXLIDEC}/src/tools/runtime"
)

add_library(polyacc_actor_lib
    pea_c_actor.c
)

# Make this directory's headers (pea_c_actor.h)
# available to other modules (like the driver).
target_include_directories(polyacc_actor_lib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link our library against the LIDE libraries it depends on.
target_link_libraries(polyacc_actor_lib PUBLIC
    "$ENV{LIDEGEN}/liblide_c_actors_basic.a"
    "$ENV{LIDEGEN}/liblide_c_edges_basic.a"
    "$ENV{LIDEGEN}/liblide_c_runtime.a"
)



