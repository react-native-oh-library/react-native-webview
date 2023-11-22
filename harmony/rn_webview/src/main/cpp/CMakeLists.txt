cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

file(GLOB rnoh_webview_SRC CONFIGURE_DEPENDS *.cpp)

add_library(
  rnoh_webview
  SHARED
  ${rnoh_webview_SRC}
)

target_include_directories(rnoh_webview PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(rnoh_webview PUBLIC rnoh)