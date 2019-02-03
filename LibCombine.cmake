# Finds all transitive static library dependencies of a given target
# including possibly the target itself.
# This will skip libraries that were statically linked that were not
# built by CMake, for example -lpthread.
macro(get_transitive_libs target out_list)
  if (TARGET ${target})
    get_target_property(libtype ${target} TYPE)
    # If this target is a static library, get anything it depends on.
    if ("${libtype}" STREQUAL "STATIC_LIBRARY")
      list(INSERT ${out_list} 0 "${target}")
      get_target_property(libs ${target} LINK_LIBRARIES)
      if (libs)
        foreach(lib ${libs})
          get_transitive_libs(${lib} ${out_list})
        endforeach()
      endif()
    endif()
  endif()
  # If we know the location (i.e. if it was made with CMake) then we
  # can add it to our list.
  LIST(REMOVE_DUPLICATES ${out_list})
endmacro()

function(combine_static_lib new_target target)

  set(all_libs "")
  get_transitive_libs(${target} all_libs)

  set(libname
      ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${new_target}${CMAKE_STATIC_LIBRARY_SUFFIX})

  if (CMAKE_CONFIGURATION_TYPES)
    list(LENGTH CMAKE_CONFIGURATION_TYPES num_configurations)
    if (${num_configurations} GREATER 1)
      set(libname
          ${CMAKE_CFG_INTDIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${new_target}${CMAKE_STATIC_LIBRARY_SUFFIX})
    endif()
  endif()

  if (MSVC)
    string(REPLACE ";" ">;$<TARGET_FILE:" temp_string "${all_libs}")
    set(lib_target_list "$<TARGET_FILE:${temp_string}>")

    add_custom_command(OUTPUT ${libname}
      DEPENDS ${all_libs}
      COMMAND lib.exe ${lib_target_list} /OUT:${libname} /NOLOGO)
  elseif(APPLE)
    string(REPLACE ";" ">;$<TARGET_FILE:" temp_string "${all_libs}")
    set(lib_target_list "$<TARGET_FILE:${temp_string}>")

    add_custom_command(OUTPUT ${libname}
      DEPENDS ${all_libs}
      COMMAND libtool -static -o ${libname} ${lib_target_list})
  else()
    string(REPLACE ";" "> \naddlib $<TARGET_FILE:" temp_string "${all_libs}")
    set(start_of_file
      "create ${libname}\naddlib $<TARGET_FILE:${temp_string}>")
    set(build_script_file "${start_of_file}\nsave\nend\n")

    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${new_target}.ar"
        CONTENT ${build_script_file}
        CONDITION 1)

    add_custom_command(OUTPUT  ${libname}
      DEPENDS ${all_libs}
      COMMAND ${CMAKE_AR} -M < ${new_target}.ar)
  endif()

  add_custom_target(${new_target}_genfile ALL
    DEPENDS ${libname})

  # CMake needs to be able to see this as another normal library,
  # so import the newly created library as an imported library,
  # and set up the dependencies on the custom target.
  add_library(${new_target} STATIC IMPORTED)
  set_target_properties(${new_target}
    PROPERTIES IMPORTED_LOCATION ${libname})
  add_dependencies(${new_target} ${new_target}_genfile)
endfunction()
