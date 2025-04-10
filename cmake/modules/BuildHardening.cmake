# This module applies hardening techniques for reproducible builds

# Global properties for reproducible builds
set_property(GLOBAL PROPERTY USE_FOLDERS OFF)
set(CMAKE_SKIP_INSTALL_RULES TRUE)
set(CMAKE_SKIP_PACKAGE_ALL_DEPENDENCY TRUE)

# Ensure consistent file ordering
set_property(GLOBAL PROPERTY GLOBAL_DEPENDS_NO_CYCLES ON)

# Force source files to be processed in a consistent order
if(NOT COMMAND force_source_file_ordering)
  function(force_source_file_ordering target)
    get_target_property(target_sources ${target} SOURCES)
    if(target_sources)
      list(SORT target_sources)
      set_target_properties(${target} PROPERTIES SOURCES "${target_sources}")
    endif()
  endfunction()
endif()


# Ensure the module is only included once
set(BUILD_HARDENING_INCLUDED TRUE)