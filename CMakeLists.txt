cmake_minimum_required(VERSION 3.16)

project(jerk-packages NONE)

set(JERK_PACKAGE_RELEASE "noble"
    CACHE STRING "Ubuntu release to package"
)

set(JERK_PACKAGES_OUTPUT_DIR
    "${CMAKE_BINARY_DIR}/packages"
    CACHE PATH "Generated package directory"
)

add_custom_target(jerk-packages ALL
    COMMAND
        ${CMAKE_COMMAND}
        "-DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}"
        "-DOUTPUT_DIR=${JERK_PACKAGES_OUTPUT_DIR}"
        "-DRELEASE=${JERK_PACKAGE_RELEASE}"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/BuildPackages.cmake"

    COMMENT "Generating Jerk packages for ${JERK_PACKAGE_RELEASE}"
    VERBATIM
)
