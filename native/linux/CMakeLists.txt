cmake_minimum_required(VERSION 3.15)
project(input_simulator_linux)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 查找X11库
find_package(X11 REQUIRED)

if(NOT X11_FOUND)
    message(FATAL_ERROR "X11库未找到")
endif()

# 检查XTest扩展
if(NOT X11_XTest_FOUND)
    message(FATAL_ERROR "XTest扩展未找到，请安装libxtst-dev")
endif()

# 创建动态库
add_library(input_simulator_linux SHARED
    input_simulator.cpp
)

# 链接X11库
target_link_libraries(input_simulator_linux
    ${X11_LIBRARIES}
    ${X11_XTest_LIB}
)

# 包含目录
target_include_directories(input_simulator_linux PRIVATE
    ${X11_INCLUDE_DIR}
)

# 设置输出目录
set_target_properties(input_simulator_linux PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

# 安装规则
install(TARGETS input_simulator_linux
    LIBRARY DESTINATION lib
)

