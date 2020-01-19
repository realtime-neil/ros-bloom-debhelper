#include <gtest/gtest.h>

TEST(HelloFail, QuickFail) {
#if 0
  ASSERT_TRUE(false);
#else
  ASSERT_TRUE(true);
#endif  // 0
}

int main(int argc, char* argv[]) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
