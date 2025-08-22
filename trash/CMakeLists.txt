cmake_minimum_required(VERSION 3.15)
project(trash LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 源文件
add_executable(trash trash.cpp)

# Windows 下显式链接 shell32.lib
if(WIN32)
    target_link_libraries(trash PRIVATE shell32 ole32)
endif()