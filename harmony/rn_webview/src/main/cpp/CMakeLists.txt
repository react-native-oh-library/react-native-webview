cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

set(rnoh_webview_generated_dir "${CMAKE_CURRENT_SOURCE_DIR}/generated")
file(GLOB_RECURSE rnoh_webview_generated_SRC "${rnoh_webview_generated_dir}/**/*.cpp")
file(GLOB rnoh_webview_SRC CONFIGURE_DEPENDS *.cpp)
add_library(rnoh_webview SHARED ${rnoh_webview_SRC} ${rnoh_webview_generated_SRC})
target_include_directories(rnoh_webview PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${rnoh_webview_generated_dir})
target_link_libraries(rnoh_webview PUBLIC rnoh)
