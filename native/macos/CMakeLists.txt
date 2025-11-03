cmake_minimum_required(VERSION 3.15)
project(input_simulator_macos)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# macOS特定设置
if(APPLE)
    # 创建动态库
    add_library(input_simulator_macos SHARED
        input_simulator.cpp
    )
    
    # 链接macOS框架
    target_link_libraries(input_simulator_macos
        "-framework ApplicationServices"
        "-framework CoreGraphics"
    )
    
    # 设置输出目录
    set_target_properties(input_simulator_macos PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        MACOSX_RPATH TRUE
    )
    
    # 安装规则
    install(TARGETS input_simulator_macos
        LIBRARY DESTINATION lib
    )
else()
    message(FATAL_ERROR "此CMakeLists.txt仅用于macOS平台")
endif()

