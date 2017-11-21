cmake_minimum_required(VERSION 3.8)
project(LearnC2)

set(CMAKE_CXX_STANDARD 11)

set(SOURCE_FILES main.cpp hello.c cudacode.cpp cudacode.cu HelloMP.c MultiplicationSeq.c MultiplicationOpenMP.c testReadFile.c cudaplus.cu test/stringcompare.c cudathrustwordcount.cu)
add_executable(LearnC2 ${SOURCE_FILES})