# Locate APR-Util include paths and libraries
include(FindPackageHandleStandardArgs)

# This module defines
# APR_UTIL_INCLUDE_DIR, where to find apr.h, etc.
# APR_UTIL_LIBRARIES, the libraries to link against to use APR.
# APR_UTIL_DLL_DIR, where to find libaprutil-1.dll
# APR_UTIL_FOUND, set to yes if found

macro(_apu_invoke _varname)
    execute_process(
        COMMAND ${APR_UTIL_CONFIG_EXECUTABLE} ${ARGN}
        OUTPUT_VARIABLE _apr_output
        RESULT_VARIABLE _apr_failed
    )

    if(_apr_failed)
        message(FATAL_ERROR "apu-1-config ${ARGN} failed with result ${_apr_failed}")
    else(_apr_failed)
        string(REGEX REPLACE "[\r\n]"  "" _apr_output "${_apr_output}")
        string(REGEX REPLACE " +$"     "" _apr_output "${_apr_output}")
        string(REGEX REPLACE "^ +"     "" _apr_output "${_apr_output}")

        separate_arguments(_apr_output)

        set(${_varname} "${_apr_output}")
    endif(_apr_failed)
endmacro(_apu_invoke)

if(NOT APU_STATIC) # apu-1-config does not yet support --static used in FindPkgConfig.cmake
find_package(PkgConfig)
pkg_check_modules(APR_UTIL apr-util-1)
endif()

if(APU_STATIC OR NOT BUILD_SHARED_LIBS)
  # Find expat for XML parsing
  find_package(EXPAT REQUIRED)
  if(TARGET EXPAT::EXPAT)
    set(EXPAT_LIBRARIES EXPAT::EXPAT)
  elseif(TARGET expat::expat)
    set(EXPAT_LIBRARIES expat::expat)
  endif()
endif()

if(APR_UTIL_FOUND)
  find_path(APR_UTIL_INCLUDE_DIR
            NAMES apu.h
            HINTS ${APR_UTIL_INCLUDE_DIRS}
            PATH_SUFFIXES apr-1)
  if (APU_STATIC OR NOT BUILD_SHARED_LIBS)
    set(APR_UTIL_COMPILE_DEFINITIONS APU_DECLARE_STATIC)
    set(APR_UTIL_LIBRARIES ${APR_UTIL_STATIC_LINK_LIBRARIES})
  else()
    set(APR_UTIL_LIBRARIES ${APR_UTIL_LINK_LIBRARIES})
  endif()
else()
  find_program(APR_UTIL_CONFIG_EXECUTABLE
      apu-1-config
      PATHS /usr/local/opt/apr-util/bin    $ENV{ProgramFiles}/apr-util/bin
      )
  mark_as_advanced(APR_UTIL_CONFIG_EXECUTABLE)
  if(EXISTS ${APR_UTIL_CONFIG_EXECUTABLE})
      _apu_invoke(APR_UTIL_INCLUDE_DIR   --includedir)
      if (APU_STATIC OR NOT BUILD_SHARED_LIBS)
        _apu_invoke(_apu_util_link_args  --link-ld)
        string(REGEX MATCH "-L([^ ]+)" _apu_util_L_flag ${_apu_util_link_args})
        find_library(APR_UTIL_LIBRARIES NAMES libaprutil-1.a PATHS "${CMAKE_MATCH_1}")
        set(APR_UTIL_COMPILE_DEFINITIONS APU_DECLARE_STATIC)
      else()
        _apu_invoke(APR_UTIL_LIBRARIES   --link-ld)
      endif()
  else()
      find_path(APR_UTIL_INCLUDE_DIR apu.h PATH_SUFFIXES apr-1)
      if (APU_STATIC OR NOT BUILD_SHARED_LIBS)
        set(APR_UTIL_COMPILE_DEFINITIONS APU_DECLARE_STATIC)
        find_library(APR_UTIL_LIBRARIES NAMES aprutil-1)
      else()
        find_library(APR_UTIL_LIBRARIES NAMES libaprutil-1)
        find_program(APR_UTIL_DLL libaprutil-1.dll)
      endif()
  endif()
endif()

find_package_handle_standard_args(APR-Util
  APR_UTIL_INCLUDE_DIR APR_UTIL_LIBRARIES)
