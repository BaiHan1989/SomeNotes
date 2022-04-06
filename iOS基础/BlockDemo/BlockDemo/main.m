//
//  main.m
//  BlockDemo
//
//  Created by 白晗 on 2022/3/30.
//

#import <Foundation/Foundation.h>

// 该命令用来生成编译后的 main.cpp 文件
// xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m -o main.cpp

/// 没有参数没有返回值的普通 block
void test(void) {
    void (^ foo)(void) = ^{
        NSLog(@"执行 block 中的代码");
    };

    foo();
}



/*
 * struct __main_block_impl_0 {
 *  struct __block_impl impl;
 *  struct __main_block_desc_0 *Desc;
 *  int num; // 被捕获到了 block 内部
 *  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _num, int flags = 0) : num(_num) {
 *      impl.isa = &_NSConcreteStackBlock;
 *      impl.Flags = flags;
 *      impl.FuncPtr = fp;
 *      Desc = desc;
 *  }
 * };
 */
/// 局部 auto 修饰的变量，变量会被捕获到 block 内部，值传递
void test1(void) {
    int num = 66;

    void (^ foo)(void) = ^{
        NSLog(@"num is %d", num); // 66
    };

    num = 88;

    foo();

}

/// 局部 static 修饰的变量，变量会被捕获到 block 内部，指针传递
void test2(void) {
    static int num = 20;

    void (^ foo)(void) = ^{
        NSLog(@"num is %d", num);
    };
    
    num = 40;
    
    foo();
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        
        test2();

    }
    return 0;
}
