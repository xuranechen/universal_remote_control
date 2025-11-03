cmake_minimum_required(VERSION 3.15)
project(input_simulator_windows)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 创建动态库
add_library(input_simulator_windows SHARED
    input_simulator.cpp
)

# Windows特定设置
if(WIN32)
    # 链接Windows库
    target_link_libraries(input_simulator_windows
        user32
    )
    
    # 设置输出目录
    set_target_properties(input_simulator_windows PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    )
endif()

# 安装规则
install(TARGETS input_simulator_windows
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
)

