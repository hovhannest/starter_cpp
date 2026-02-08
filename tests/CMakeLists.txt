find_package(GTest REQUIRED)

add_executable(medit_tests test_main.cpp)

target_link_libraries(medit_tests PRIVATE GTest::gtest_main)

include(GoogleTest)
gtest_discover_tests(medit_tests)
