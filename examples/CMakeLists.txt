cmake_minimum_required (VERSION 3.1.0)
PROJECT (REST_VOL_EXAMPLES)

#-----------------------------------------------------------------------------
# Apply Definitions to compiler in this directory and below
#-----------------------------------------------------------------------------
add_definitions (${REST_VOL_EXTRA_C_FLAGS})

#-----------------------------------------------------------------------------
# Define Sources
#-----------------------------------------------------------------------------
set (examples
    rv_crtdat
    rv_rdwt
    rv_crtatt
    rv_crtgrp
    rv_crtgrpar
    rv_crtgrpd
    rv_subset
    rv_write
    rv_read
    rv_chunk_read
    rv_compound
    rv_group
    rv_select
    rv_attribute
    rv_extlink
)

foreach (example ${examples})
  add_executable (${example} ${REST_VOL_EXAMPLES_SOURCE_DIR}/${example}.c)
  TARGET_C_PROPERTIES (${example} STATIC " " " ")
  target_link_libraries (${example} PUBLIC ${REST_VOL_LIB_TARGET} ${HDF5_LIBRARIES_TO_EXPORT})
  set_target_properties (${example} PROPERTIES FOLDER examples)
  if (NOT PREBUILT_HDF5_DIR)
    add_dependencies(${example} ${REST_VOL_LIB_TARGET} ${HDF5_LIBRARIES_TO_EXPORT})
  endif ()
  if (BUILD_SHARED_LIBS)
    add_executable (${example}-shared ${REST_VOL_EXAMPLES_SOURCE_DIR}/${example}.c)
    TARGET_C_PROPERTIES (${example}-shared SHARED " " " ")
    target_link_libraries (${example}-shared PUBLIC ${REST_VOL_LIBSH_TARGET} ${HDF5_LIBRARIES_TO_EXPORT})
    set_target_properties (${example}-shared PROPERTIES FOLDER examples)
    if (NOT PREBUILT_HDF5_DIR)
      add_dependencies(${example}-shared ${REST_VOL_LIBSH_TARGET} ${HDF5_LIBRARIES_TO_EXPORT})
    endif ()
  endif (BUILD_SHARED_LIBS)

  #-----------------------------------------------------------------------------
  # Add Target(s) to CMake Install for import into other projects
  #-----------------------------------------------------------------------------
  if (REST_VOL_EXPORTED_TARGETS)
    install (
        TARGETS
            ${example}
        EXPORT
            ${REST_VOL_EXPORTED_TARGETS}
        DESTINATION
            ${REST_VOL_INSTALL_DATA_DIR}/rest_vol_examples COMPONENT examples
    )
  endif ()
endforeach (example ${examples})

add_subdirectory(hl ${PROJECT_BINARY_DIR}/examples)

if (BUILD_TESTING)
  include (${REST_VOL_EXAMPLES_SOURCE_DIR}/CMakeTests.cmake)
endif (BUILD_TESTING)
