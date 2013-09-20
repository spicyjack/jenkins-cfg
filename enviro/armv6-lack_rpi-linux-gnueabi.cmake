# this one is important
SET(CMAKE_SYSTEM_NAME Linux)
include(CMakeForceCompiler)
#this one not so much
SET(CMAKE_SYSTEM_VERSION 1)

# specify the cross compiler
SET(CMAKE_C_COMPILER /opt/cross/armv6-lack_rpi-linux-gnueabi/bin/armv6-lack_rpi-linux-gnueabi-gcc)
SET(CMAKE_CXX_COMPILER /opt/cross/armv6-lack_rpi-linux-gnueabi/bin/armv6-lack_rpi-linux-gnueabi-g++)

# where is the target environment 
SET(CMAKE_FIND_ROOT_PATH /opt/cross/armv6-lack_rpi-linux-gnueabi/armv6-lack_rpi-linux-gnueabi/sysroot ${WORKSPACE}/artifacts)

# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
