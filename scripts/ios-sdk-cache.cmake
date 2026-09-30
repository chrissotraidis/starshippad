# An older configure can leave host-SDK find_library/find_path results cached.
# Changing the sysroot does not invalidate them, so forget only those results.
# Keep dependency locations, build options and all files in the build tree.
get_cmake_property(_starshippad_cache_variables CACHE_VARIABLES)
foreach(_starshippad_variable IN LISTS _starshippad_cache_variables)
    get_property(_starshippad_value CACHE "${_starshippad_variable}" PROPERTY VALUE)
    if("${_starshippad_value}" MATCHES "/MacOSX\\.platform/|/MacOSX[^/]*\\.sdk/")
        unset("${_starshippad_variable}" CACHE)
    endif()
endforeach()
