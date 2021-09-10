## 一、Block 的本质

**`block` 的本质是一个 OC 对象。**

看下面一段代码，关于 `block` 的基本使用：

```objective-c
int main(int argc, const char *argv[])
{
    @autoreleasepool {
        void (^ aBlock)(void) = ^{
            NSLog(@"this is a block");
        };

        aBlock();
    }
    return 0;
}
```

- 定义一个 `block` ，在 `block` 中执行一句代码，之后调用 `block`
- 可以通过 `clang` 编译器来查看一下编译后 `block` 是如何实现的：

```cpp
struct __block_impl {
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
};

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

// 封装了 block 执行的代码
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_5k_slnd0jd17fsb0qlp4fp4w09m0000gn_T_main_91fc10_mi_0);
        
}

static struct __main_block_desc_0 {
    size_t reserved;
    size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0) };

// main 函数
int main(int argc, const char *argv[])
{
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
        void (* aBlock)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));

        ((void (*)(__block_impl *))((__block_impl *)aBlock)->FuncPtr)((__block_impl *)aBlock);
    }
    return 0;
}
```

- 编译后的 `main` 函数，首先是调用了 `__main_block_impl_0` 函数，并传入了2个参数，分别为 `__main_block_func_0` 和 `&__main_block_desc_0_DATA`

- `__main_block_impl_0` 函数是 `__main_block_impl_0` 结构体的构造函数，第一个参数接收的是一个指针，指针指向的是 `__main_block_func_0` 函数，该函数中封装了 `block` 中的代码。第二个参数传入的是 `block` 的一些描述包含 `block` 占用的内存大小信息
- `__main_block_impl_0` 函数因为是一个构造函数，返回结果就是 `__main_block_impl_0` 结构体的变量，在构造函数中给 `__block_impl` 结构体成员进行赋值，将函数地址复制给了 `FuncPtr` 指针。
- `__main_block_impl_0` 结构体的就是 `block` 的本质，它有一个结构体成员 `__block_impl`，在 `__block_impl` 结构体里面又包含了 `isa` 指针，从这方面说明了 `block` 的本质是一个OC对象，`isa` 指针指向了该 `block` 的类，`__block_impl` 结构体里还包含了 `FuncPtr` 指针，在给结构体赋值的时候，该指针指向了 `__main_block_func_0`函数，在调用 `block` 的时候，通过该指针进行函数调用。

上面情况中的 `block` 没有参数也没有返回值，如果在 `block` 中传递参数，那么 `block` 的结构又是什么样的呢？

```objective-c
void (^ aBlock)(int, int) = ^(int a, int b){
    NSLog(@"a is %d, b is %d", a, b);
};

aBlock(10, 20);
```

继续通过 `clang` 编译器查看一下生产的cpp代码：

```cpp
static void __main_block_func_0(struct __main_block_impl_0 *__cself, int a, int b) {

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_5k_slnd0jd17fsb0qlp4fp4w09m0000gn_T_main_c68cfa_mi_0, a, b);
}
```

- 只是在 `__main_block_func_0` 函数中传入了2个参数，`block` 的结构体并没有发生任何变化。

## 二、Block 的变量捕获

### 2.1 局部变量的捕获（auto变量）

请问，下面的代码打印结果是什么？

```objective-c
int main(int argc, const char *argv[])
{
    @autoreleasepool {
        int num = 6;
        void (^ aBlock)(void) = ^{
            NSLog(@"num is %d", num);
        };
        
        num = 66;
        aBlock();
    }
    return 0;
}
```

- 答案是 num is 6
- 通过上面的打印结果会产生一个疑问，为啥我先修改了 `num` 的值再调用 `block` 而打印结果是 num is 6。接下来就来研究一下：

还是通过 `clang` 编译器生成 cpp 代码来寻找答案

首先观察 `main` 函数

```cpp
int main(int argc, const char *argv[])
{
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
        int num = 6;
        void (* aBlock)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, num));

        num = 66;
        ((void (*)(__block_impl *))((__block_impl *)aBlock)->FuncPtr)((__block_impl *)aBlock);
    }
    return 0;
}
```

- `__main_block_impl_0` 函数除了和之前一样传递了2个参数外，还传递了一个参数就是 `num`。

```cpp
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int num;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _num, int flags=0) : num(_num) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

- 在 `block` 的结构体中多出了一个成员变量 `num`，刚才传递的参数 `num` 的值6被赋值给了该结构体。

**接下来我们修改 `num` 的值，改成了66。我们只是改变了局部变量 `num` 的值并没有修改 `block` 结构体中 `num` 的值**

调用 `block`，本质就是通过 `FuncPtr` 指针来调用 `__main_block_func_0` 函数：

```cpp
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int num = __cself->num; // bound by copy

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_5k_slnd0jd17fsb0qlp4fp4w09m0000gn_T_main_dbf0b3_mi_0, num);
}
```

- 该函数中通过 `struct __main_block_impl_0 *__cself` 函数指针取出里面的成员 `num` 的值，最后进行打印，所以打印的结果是6。

综合以上分析，可以得出一个结论：**`block` 会将局部变量捕获到自己的内部，捕获的是局部变量的值**。

### 2.2 局部变量的捕获（static变量）

继续看下面的代码的打印结果是什么？

```objective-c
int main(int argc, const char *argv[])
{
    @autoreleasepool {
        
        static int num = 10;
        void (^ aBlock)(void) = ^{
            NSLog(@"num is %d", num);
        };
        num = 20;
        aBlock();
    }
    return 0;
}
```

答案是 num is 20。

继续查看编译后的 cpp 代码，首先看 `main` 函数：

```cpp
int main(int argc, const char *argv[])
{
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 

        static int num = 10;
        void (* aBlock)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, &num));
                            
        num = 20;
        ((void (*)(__block_impl *))((__block_impl *)aBlock)->FuncPtr)((__block_impl *)aBlock);
    }
    return 0;
}
```

- 这次给 `__main_block_impl_0` 函数传递的**第三个参数传递的是 `num` 的地址**。

```cpp
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int *num;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int *_num, int flags=0) : num(_num) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

- `__main_block_impl_0` 结构体成员中多的是 `num` 的指针。

再观察一下 `block` 的调用：

```cpp
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int *num = __cself->num; // bound by copy

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_5k_slnd0jd17fsb0qlp4fp4w09m0000gn_T_main_a3338a_mi_0, (*num));
}
```

- 获取到 `num` 的指针之后，**在调用阶段通过 `*num` 获取指针所指向内存地址中的值**。

通过以上分析可知 `num` 的值发生改变是理所应当的了。

结论：无论是被 `static` 修饰的局部变量还是默认被 `auto` 修饰的局部变量都会被 `block` 捕获，只不过 `static` 修饰的局部变量是地址传递，`auto` 修饰的局部变量是值传递。

### 2.3 全局变量

运行下面代码的打印结果是什么？

```objective-c
int num = 10;
static int num2 = 10;

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        
        void (^ aBlock)(void) = ^{
            NSLog(@"num is %d , num2 is %d", num, num2);
        };
        num = 20;
        num2 = 20;
        aBlock();
    }
    return 0;
}

```

- 这次，我们将 `block` 中用到的变量换成了全局变量，打印结果都是20

继续查看一下本质：

```cpp
int num = 10;
static int num2 = 10;

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

static void __main_block_func_0(struct __main_block_impl_0 *__cself) {

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_5k_slnd0jd17fsb0qlp4fp4w09m0000gn_T_main_9bca35_mi_0, num, num2);
}
```

- 在 `block` 的结构体中并没有捕获全局变量，在 `block` 执行的代码中直接访问全局变量，因为全局变量的内存会一直存在，直接获取全局变量的值直接访问就可以了。

## 三、Block的类型

我们已经知道 `block` 的本质是一个OC对象，那么一个OC对象是一定有他所属的类型的。`block` 也不例外，看下面的代码打印结果是什么？

```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        void (^aBlock)(void) = ^{
            NSLog(@"this is a block");
        };
        
        NSLog(@"%@", [aBlock class]);
        NSLog(@"%@", [[aBlock class] superclass]);
        NSLog(@"%@", [[[aBlock class] superclass] superclass]);
        NSLog(@"%@", [[[[aBlock class] superclass] superclass] superclass]);
    }
    return 0;
}
```

- 打印结果依次为：`__NSGlobalBlock__` => `__NSGlobalBlock` => `NSBlock` => `NSObject`
- 通过一层层的调用，我们最终发现一个 `block` 最终是继承 `NSObject` 的，所以从侧面也可以证明 `block` 本质是一个 OC 对象。

`block`是有3种类型的，除去上面我们打印的 `__NSGlobalBlock__`类型，还有2种类型，分别为 `__NSStackBlock__` 和 `__NSMallocBlock__`。

在研究 `block` 的类型之前，**我们需要先将项目调整为 `MRC` 环境**，这样才可以真正研究出 `block` 的类型，因为 `ARC` 环境下，编译器会默默为我们做一些事情。



### 3.1 \__NSGlobalBlock__

全局的静态 `block`，不会访问任何外部变量

`MRC`环境下，代码如下：

```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        void (^ aBlock) (void) = ^{
            NSLog(@"this is a block");
        };
        
        NSLog(@"%@", [aBlock class]);
        
    }
    return 0;
}
```

- 在 `block` 中没有捕获 `auto` 修饰的局部变量，那么它的类型就是 `__NSGlobalBlock__`
- 该 `block` 是存储在内存中的数据段的。

### 3.2 \__NSStackBlock__

保存在栈中的 `block`，当函数返回时会被销毁

`MRC`环境下，代码如下：

```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        int num = 10;
        void (^aBlock)(void) = ^{
            NSLog(@"num is %d", num);
        };
        
        NSLog(@"%@", [aBlock class]);
        
    }
    return 0;
}
```

- `block` 捕获 `auto` 修饰的局部变量，此时它的类型就是`__NSStackBlock__`。
- 该 `block` 是存储在内存中的栈区的，既然存储在栈区，说明它的内存创建和销毁不是程序员控制的，所以如果我们在它的作用域外再去使用它就会出现问题

```objective-c
void (^aBlock)(void);

void test() {
    int num = 10;
    aBlock = ^{
        NSLog(@"num is %d", num);
    };
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        test();
        
        aBlock();
    }
    return 0;
}
```

- 在 `main` 函数中先调用 `test` 函数创建了 `block` 并且 `block` 捕获了局部变量，之后调用 `block` 来查看一下打印结果：`num is -272632744`，这并不是我们想要的结果。这是什么原因呢？
- 因为该 `block` 是在栈区的，一开始确实捕获了 `num` 的值存在了 `block` 里，随着 `test` 函数执行完毕 `block` 也在栈区被销毁，里面的成员 `num` 已经被赋值给垃圾数据了。所以当我们再通过全局的变量 `aBlock` 调用该 `block` 的时候打印的就是垃圾数据，没有任何意义了。

如何来保住 `block` 的命呢？那就需要把 `block` 移动到堆区，由程序员来控制其什么时候销毁。

### 3.3 \__NSMallocBlock__

保存在堆中的 `block`，当引用计数为0时会被销毁

`MRC`环境下，代码如下：

```objective-c
void (^aBlock)(void);

void test() {
    int num = 10;
    aBlock = [^{
        NSLog(@"num is %d", num);
    } copy];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        test();
        
        aBlock();
    }
    return 0;
}
```

- 此时打印的结果就是：num is 10
- 在 `test` 函数中对 `block` 进行 `copy` 操作，那么此时的 `block` 类型就是 `__NSMallocBlock__`
- `__NSMallocBlock__` 在内存中处于堆区。
- 如果我们对 `__NSMallocBlock__` 再进行 `copy` 操作呢？它还是在堆区，只不过引用计数会进行+1的操作

我们在 `MRC` 的环境下，探究了 `block` 的类型。我们平时的开发都在 `ARC` 环境下，`ARC` 环境下编译器会在**某些时刻**自动为 `block` 进行 `copy` 操作。

1. `block` 作为函数返回值并且 `block` 内部捕获了 `auto` 修饰的变量。

```objective-c
typedef void(^LLBlock)(void);

LLBlock testBlock() {
    
    int num = 10;
    
    return ^{
        NSLog(@"num is %d", num);
    };
    
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        LLBlock aBlock = testBlock();
        
        NSLog(@"%@", [aBlock class]);
        
    }
    return 0;
}

打印结果：__NSMallocBlock__
```

- `block` 被强指针引用并且 `block` 内部捕获了 `auto` 修饰的变量

```objective-c
typedef void(^LLBlock)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        int num = 20;
        
        LLBlock aBlock = ^{
            NSLog(@"num is %d", num);
        };
        
        NSLog(@"%@", [aBlock class]);		// __NSMallocBlock__
        
      	// 没有被强指针引用的 block
        NSLog(@"%@", [^{
            NSLog(@"num is %d", num);
        } class]); 					// __NSStackBlock__
        
    }
    return 0;
}

```

- `GCD` API中使用到的 `block` 和 `CocoaAPI`中带有 `UsingBlock` 字样的 `block`
  - `enumerateObjectsUsingBlock`
  - `void dispatch_async(dispatch_queue_t queue, dispatch_block_t block);` 等

## 四、对象类型的auto变量内存管理

在之前我们探究过 `block` 针对 `auto` 修饰的局部变量的捕获问题，那时我们定义变量使用的是基本数据类型，接下来我们研究一下定义对象类型 `block` 是如何进行内存管理的。

首先看下面的代码：

```objective-c
// Person.m
@implementation Person

- (void)dealloc {
    NSLog(@"person - dealloc");
}

@end

// main.m
typedef void(^MyBlock)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        MyBlock myBlock;
        
        {
            Person *person = [[Person alloc] init];
            myBlock = ^{
                NSLog(@"person is %@", person);
            };
            
        }
        myBlock();
    }
    return 0;
}

// 打印结果：
person is <Person: 0x10288f260>
person - dealloc
```

- 创建一个 `Person` 类，并重写它的 `dealloc` 方法，目的是监控 `Person` 对象什么时候销毁。
- 在 `main` 函数中，使用 `{}` 代码块生成局部作用域，当 `{}` 的代码执行完毕后，来监控 `person` 对象是否会销毁。
- 因为使用 `myBlock` 强引用着 `block` 对象，在 `ARC` 环境下编译器会对 `block` 自动进行 `copy` 操作，所以此时 `block` 的处于**堆区**，在 `block` 中同时捕获了 `auto` 修饰的 `person` 对象，所以会对 `person` 对象的引用计数+1，保证 `person` 对象在 `{}` 执行完毕后不会销毁。

通过 `xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc -fobjc-runtime=ios-8.0.0 main.m` 命令查看一下编译器生成的 c++ 代码。

```cpp
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  Person *__strong person;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, Person *__strong _person, int flags=0) : person(_person) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

- `block` 内部捕获了 `person` 对象而且是一个强引用

再观察一下 `desc` 这个结构体

```cpp
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->person, (void*)src->person, 3/*BLOCK_FIELD_IS_OBJECT*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->person, 3/*BLOCK_FIELD_IS_OBJECT*/);}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
```

- 该结构体多出了2个函数指针。分别调用是 `__main_block_copy_0` 和 `__main_block_dispose_0`两个函数
- 在 `__main_block_copy_0` 函数中，调用了 `_Block_object_assign` 函数处理对象引用计数的增加
- 在 `__main_block_dispose_0`函数中，调用了 `_Block_object_dispose` 函数处理对象引用计数的减少

如果我们对上面的代码进行一下改造：

```objective-c
typedef void(^MyBlock)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        MyBlock myBlock;
        
        {
            Person *person = [[Person alloc] init];
            // 将 person 对象修改为弱引用
            __weak Person *weakPerson = person;
            myBlock = ^{
                NSLog(@"person is %@", weakPerson);
            };
            
        }
        
        myBlock();
        
    }
    return 0;
}

// 打印结果：
person - dealloc
person is (null)
```

- 使用弱指针指向 `person` 对象并在 `block` 中调用。
- 此时，`block` 虽然捕获了 `person` 对象，但是并没有使 `person` 对象的引用计数+1，所以当 `{}` 代码执行完毕后，`person` 对象就先销毁了，之后调用 `block` 打印结果 `person` 就是空了。
- 此时，`__main_block_impl_0` 中 `person` 指针是弱引用的。

**总结来说：在 `ARC` 环境下，在堆区存在的 `block` 会对 `auto` 修饰的对象类型默认进行一个强引用，目的是在 `block` 内部用到 `person` 对象时保证 `person` 对象不被销毁。如果我们不希望 `block` 内部对对象类型进行强应用，可以用弱指针指向该对象。**

如果 `block` 在栈区呢？

如果 `block` 在栈区，`block` 的内存就不再受到我们程序员的控制，此时我们就需要对 `block` 进行 `copy` 操作，把它复制到堆区，这样 `block` 内部捕获的对象类型变量才不会被销毁。如果不对 `block` 进行 `copy` 操作，不会对 `block` 内部捕获的对象类型进行引用计数+1的操作。

## 五、__block

提问：是否可以修改 `block` 中使用到变量的值？如果可以，都有哪几种方式？

1. 将变量定义为 `static` 类型

2. 定义一个全局变量

3. 使用 `__block`的方式

由于前2种方式会导致变量的内存一直不会销毁，**所以通常开发中使用 `__block` 修饰变量，在 `block` 中对变量进行修改**

```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        __block int num = 10;
        
        void (^block)(void) = ^{
            num = 20;
            NSLog(@"num is %d", num);
        };
        
        block();
        
    }
    return 0;
}
// 打印结果
num is 20
```

还是通过 `clang` 编译器来查看一下编译后的 C++ 代码

首先看 `main` 函数：

```cpp
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 

        __attribute__((__blocks__(byref))) __Block_byref_num_0 num = {(void*)0,(__Block_byref_num_0 *)&num, 0, sizeof(__Block_byref_num_0), 10};

        void (*block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, (__Block_byref_num_0 *)&num, 570425344));

        ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);

    }
    return 0;
}
```

- 变量加上 `__block` 之后，定义的变量的类型不是简单的 `int` 类型了，而是 `__Block_byref_num_0` 类型。在 `__Block_byref_num_0` 中的传值过程中，第2个参数将 `num` 的地址传递了进去，第4个参数才是 `num` 的值。

```cpp
struct __Block_byref_num_0 {
  void *__isa;
__Block_byref_num_0 *__forwarding;
 int __flags;
 int __size;
 int num;
};

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_num_0 *num; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_num_0 *_num, int flags=0) : num(_num->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

- `__Block_byref_num_0` 成员中包含了 `isa` 和它同样类型的 `__forwarding` 指针，最后1个参数才是用来存储 `num` 变量的成员，有 `isa` 指针说明它是一个对象，`__forwarding`指针用来指向它自己。
- 再看 `block` 的结构，不再直接保存 `num` 而是 保存了 `__Block_byref_num_0` 指针，指向 `__Block_byref_num_0` 结构体。

```cpp
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  __Block_byref_num_0 *num = __cself->num; // bound by ref

            (num->__forwarding->num) = 20;
            NSLog((NSString *)&__NSConstantStringImpl__var_folders_5k_slnd0jd17fsb0qlp4fp4w09m0000gn_T_main_f080da_mi_0, (num->__forwarding->num));
}
```

- `block` 的调用本质是调用该函数，我们可以看到 `block` 通过 `__Block_byref_num_0`  指针找到 `__forwarding` 找到 `num` 最终修改 `num` 的值。

通过上面的代码分析，我们发现在 `auto` 修饰的局部变量上加上了 `__block` 本质是把该变量包装成了一个对象，通过该对象来修改 `num` 的值。

在 `ARC` 的环境下，`block` 捕获`auto`修饰的局部变量是通过 `copy` 复制到了堆区。因为 `__block`  会将变量包装成 `__Block_byref_num_0` 对象，`__Block_byref_num_0` 也会被拷贝到堆区，那么肯定要进行内存管理，内存管理就用到了 `__main_block_desc_0` 结构体中的 `__main_block_copy_0` 函数 和 `__main_block_dispose_0` 函数。

```cpp
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->num, (void*)src->num, 8/*BLOCK_FIELD_IS_BYREF*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->num, 8/*BLOCK_FIELD_IS_BYREF*/);}
```

- `__main_block_copy_0` 函数内部调用了 `_Block_object_assign` 函数来对 `num` 进行强引用
- 当 `block` 被销毁的时候又会调用 `__main_block_dispose_0` 函数中的 `_Block_object_dispose` 函数，对 `num` 进行销毁操作

接下来，我们研究一下更复杂的情况，`__block` 修饰对象类型。先看下面的代码：

```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        __block NSObject *obj = [[NSObject alloc] init];
        
        void (^block) (void) = ^{
            NSLog(@"%@", obj);
        };
        
        block();
        
    }
    return 0;
}
```

使用 `clang` 编译器来生成对应的 C++ 代码：

```cpp
struct __Block_byref_obj_0 {
  void *__isa;
__Block_byref_obj_0 *__forwarding;
 int __flags;
 int __size;
 void (*__Block_byref_id_object_copy)(void*, void*);
 void (*__Block_byref_id_object_dispose)(void*);
 NSObject *__strong obj;
};

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_obj_0 *obj; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_obj_0 *_obj, int flags=0) : obj(_obj->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

- 先看 `block` 的结构体，被 `__block` 修饰的对象类型也会被包装成一个对象类型即 `__Block_byref_obj_0`
- `__Block_byref_obj_0` 的 `obj `指针就指向了` __Block_byref_obj_0` 结构体，在结构体中有一个强引用的 `obj` 指针指向 `NSObject `对象

 由于被包装成了一个对象，那么一定会涉及内存的管理：

```cpp
static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};

static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->obj, (void*)src->obj, 8/*BLOCK_FIELD_IS_BYREF*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->obj, 8/*BLOCK_FIELD_IS_BYREF*/);}
```

- `__Block_byref_obj_0` 对象的内存通过 `__main_block_desc_0` 结构体中的 `__main_block_impl_0` 函数和 `__main_block_impl_0` 进行管理
- 当 `block` 被拷贝到堆区的时候，调用 `__main_block_copy_0` 函数中的 `_Block_object_assign` 函数进行强引用
- 当 `block` 被销毁的时候，调用 `__main_block_dispose_0` 函数中的` _Block_object_dispose `函数进行对象的销毁

我们再看 `__Block_byref_obj_0` 结构体中 也存在2个函数，分别为 `__Block_byref_id_object_copy` 和 `__Block_byref_id_object_dispose`

```cpp
static void __Block_byref_id_object_copy_131(void *dst, void *src) {
 _Block_object_assign((char*)dst + 40, *(void * *) ((char*)src + 40), 131);
}
static void __Block_byref_id_object_dispose_131(void *src) {
 _Block_object_dispose(*(void * *) ((char*)src + 40), 131);
}
```

- `__Block_byref_id_object_copy_131` 函数会根据 `__Block_byref_obj_0` 中 `obj` 的指针是强指针还是弱指针来对 `obj` 对象强引用和弱引用。
- `__Block_byref_id_object_dispose_131` 函数会在 `__Block_byref_obj_0` 对象销毁时来销毁 `obj` 对象。

> 注意一种情况，我们上面研究的都是 ARC 环境下的情况，如果在 MRC 环境下，即使我们主动对 block 对象进行copy操作，使用 __block 修饰的对象类型，在 block 内部也不会被强引用

## 六、循环引用

在使用 `block` 的时候经常遇到的问题就是循环引用问题从而导致内存泄漏。看下面的代码：

```objective-c
// Person.h

typedef void(^MyBlock)(void);

@interface Person : NSObject
@property (nonatomic, copy) MyBlock block;
@end

// Person.m
@implementation Person

- (void)dealloc {
    NSLog(@"Person 对象销毁");
}

@end

// main 函数
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        Person *person = [[Person alloc] init];
        
        person.block = ^{
            NSLog(@"%p", person);
        };
        
        person.block();
    }
    return 0;
}
```

- 定义一个 `Person` 类，并定义一个 `block` 属性，在 `person.m` 文件中通过` dealloc` 方法来观察 `person` 对象是否销毁
- 在 `main` 函数中，让 `person` 的 `block` 属性强引用着一个 `block`，在 `block` 内部调用 `person`对象，`block` 就会捕获 `person` 对象并强引用着它。
- 当 `main` 函数执行完毕，`person` 对象不会被销毁，就因为 `block` 和 `person` 的相互引用导致的循环引用发生了内存泄漏，`person `对象没有被销毁。

该如何解决循环引用呢？下面使用3种方式来解决

1. `__weak`

循环引用是因为 `block` 和 `person` 对象之间的强引用导致的，可以使用 `__weak` 来把其中一个引用换成弱引用即可

```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        Person *person = [[Person alloc] init];
        
        __weak typeof(person) weakPerson = person;
        person.block = ^{
            NSLog(@"%p", weakPerson);
        };
        
        person.block();
    }
    return 0;
}
```

- 当 `main` 函数执行完毕，`person`对象也会被销毁
- 当 `person` 对象被销毁后，使用 `__weak` 修饰的对象会指向 `nil`

2. `_unsafe_unretained`

```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        Person *person = [[Person alloc] init];
        
        __unsafe_unretained typeof(person) weakPerson = person;
        person.block = ^{
            NSLog(@"%p", weakPerson);
        };
        
        person.block();
    }
    return 0;
}
```

- 使用 `_unsafe_unretained` 和 `__weak` 一样不会强引用对象，但是当对象销毁后，它仍然保存着该对象的地址，如果我们再次访问该对象会产生野指针。

3. `__block`

```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        __block Person *person = [[Person alloc] init];
        
        person.block = ^{
            NSLog(@"%p", person);
            person = nil;
        };
        
        person.block();
    }
    return 0;
}
```

- 通过 `__block` 解决循环引用必须要调用 `block`，并且在 `block` 的内部必须将 `person` 对象置为 `nil`。
- 由于 `__block` 本质会重新包装一个对象，该对象强引用着 `person` 对象，`person` 对象强引用着 `block` ，`block` 又强引用着该对象，他们三个形成互相引用的状态。想要解决循环引用就主动把 `person` 对象置为 `nil` 来破坏之间的引用关系。

### 修改于2020.5.22