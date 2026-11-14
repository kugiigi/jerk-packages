
if(NOT DEFINED SOURCE_DIR OR
   NOT DEFINED OUTPUT_DIR OR
   NOT DEFINED RELEASE)
    message(FATAL_ERROR
        "SOURCE_DIR, OUTPUT_DIR and RELEASE are required")
endif()

find_program(TAR_EXECUTABLE tar REQUIRED)

file(MAKE_DIRECTORY "${OUTPUT_DIR}")

# Remove previously generated archives.
file(GLOB OLD_PACKAGES "${OUTPUT_DIR}/*.jerk")
if(OLD_PACKAGES)
    file(REMOVE ${OLD_PACKAGES})
endif()

# Recursively find every directory.
file(GLOB_RECURSE ALL_ENTRIES
    LIST_DIRECTORIES true
    "${SOURCE_DIR}/*"
)

set(PACKAGE_COUNT 0)
set(PACKAGE_NAMES "")

foreach(ENTRY IN LISTS ALL_ENTRIES)

    if(NOT IS_DIRECTORY "${ENTRY}")
        continue()
    endif()

    get_filename_component(DIR_NAME "${ENTRY}" NAME)

    # Only process directories matching the selected release.
    if(NOT DIR_NAME STREQUAL "${RELEASE}")
        continue()
    endif()

    set(RELEASE_DIR "${ENTRY}")

    get_filename_component(PACKAGE_DIR "${RELEASE_DIR}" DIRECTORY)
    get_filename_component(PACKAGE_NAME "${PACKAGE_DIR}" NAME)

    # Validate package contents.
    if(NOT EXISTS "${RELEASE_DIR}/MOD" OR
       NOT EXISTS "${RELEASE_DIR}/ORIG")
        message(WARNING
            "Skipping ${RELEASE_DIR}: MOD or ORIG missing")
        continue()
    endif()

    # Prevent silently overwriting packages with identical names.
    list(FIND PACKAGE_NAMES "${PACKAGE_NAME}" PACKAGE_INDEX)

    if(NOT PACKAGE_INDEX EQUAL -1)
        message(FATAL_ERROR
            "Duplicate package name: ${PACKAGE_NAME}")
    endif()

    list(APPEND PACKAGE_NAMES "${PACKAGE_NAME}")

    set(OUTPUT_FILE "${OUTPUT_DIR}/${PACKAGE_NAME}.jerk")

    message(STATUS "Archiving: ${PACKAGE_NAME} (${RELEASE})")

    execute_process(
        COMMAND "${TAR_EXECUTABLE}"
            -czf "${OUTPUT_FILE}"
            -C "${RELEASE_DIR}"
            MOD
            ORIG
            config
        RESULT_VARIABLE TAR_RESULT
        ERROR_VARIABLE TAR_ERROR
    )

    if(NOT TAR_RESULT EQUAL 0)
        message(FATAL_ERROR
            "Failed to archive ${PACKAGE_NAME}: ${TAR_ERROR}")
    endif()

    math(EXPR PACKAGE_COUNT "${PACKAGE_COUNT} + 1")

endforeach()

message(STATUS
    "Successfully generated ${PACKAGE_COUNT} packages for ${RELEASE}")
