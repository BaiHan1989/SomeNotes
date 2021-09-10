## 一、简介

在 Swift 语言还没有出现的时候， iOS 开发使用的是 Objective-C 这门语言，Objective-C 是 C 语言的超集，Objective-C 的代码底层都是由 C/C++ 代码实现的。Objective-C 中的对象、类主要是基于 C/C++ 中的**结构体**实现的。接下来就研究一下 `OC` 对象的本质。

## 二、OC对象的本质

创建一个`NSObject`对象，使用`obj`指针指向了这个对象。

```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSObject *obj = [[NSObject alloc] init];
    }
    return 0;
}
```

我们可以利用 `clang` 编译器将 Objective-C 代码转换成 C/C++ 代码，转换成的代码是编译后的 C/C++ 代码，本质并不是运行时的代码，但也可以帮助我们探究一下底层的实现
- 打开终端，来到目标源文件所在目录，执行下面的命令，执行结束得到输出的 CPP 文件。

```shell
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc 目标OC源文件 -o 输出的CPP文件

以main.m 为例 -> main-arm64.cpp
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m -o mani-arm64.cpp
```

- 我们通过Xcode进入`NSObject`的声明文件中，看下`NSObject`是如何定义的
  - 在 `NSObject`的定义中，有成员即`isa`，是`Class`类型的
  - `Class`是通过关键字`typedef`重新命名的类型，可以看出`Class`类型本质就是`struct objc_class *`类型，即指向结构体的指针，也就是说`isa`就是一个指向结构体的**指针**
  - 每个对象的内部都会有一个 `isa` 指针

```objective-c
@interface NSObject {
    Class isa;
}
...
@end

typedef struct objc_class *Class;
```

- 我们再从生成的 cpp 文件中找到 `NSObject` 的实现：可以看出 `NSObject` 类编译后是通过**结构体**实现的。结构体中有一个成员，就是 `isa`

```objective-c
struct NSObject_IMPL {
	Class isa;
};
```

综上，我们可以得出一个结论：**`NSObject`类本质是结构体实现的，里面有一个`isa`指针，而指针在64位的环境下指针是占用8个字节的。**

- 我们还可以利用系统提供的一些函数来查看占用内存空间的大小。

```objective-c
#import <objc/runtime.h>
#import <malloc/malloc.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSObject *obj = [[NSObject alloc] init];
        
        // 获取 NSObject 类中成员变量所占用的内存大小
        NSLog(@"%zd", class_getInstanceSize([NSObject class])); // 8
        
        // 获取obj指针所指向的对象占用内存空间大小
        NSLog(@"%zd", malloc_size((__bridge const void *)obj)); // 16
    }
    return 0;
}
```

使用`class_getInstanceSize(Class cls)`这个函数可以查看某个类中**成员变量**所占用的内存空间大小。**注意：返回的是内存对齐之后的成员变量占用内存大小**

我们从上面已经知道，`NSObject`类中只有一个 `isa` 指针，所以从打印结果看出 `NSObject` 类中的实例是占用8个字节的。

使用`extern size_t malloc_size(const void *ptr);`这个函数，是传递一个指针，返回这个指针指向对象所占用的内存空间大小。

**可以发现，系统为`NSObject`的对象分配了16个字节的存储空间，其中前8个字节存放的是isa指针。**

我们可以从`objc4-781`的源码进行一下探索：

- 找到`class_getInstanceSize`函数：（以NSObject类为例）
  - 调用`alignedInstanceSize`函数
  - 调用`word_align`函数，传入`unalignedInstanceSize()`，实例对象 `size` 就是8。
  - `word_align`计算结果就是8。

```objective-c
// objc-class.mm 文件
size_t class_getInstanceSize(Class cls)
{
    if (!cls) return 0;
    return cls->alignedInstanceSize();
}

// objc-runtime-new.h
// Class's ivar size rounded up to a pointer-size boundary.
uint32_t alignedInstanceSize() const {
    return word_align(unalignedInstanceSize());
}

uint32_t unalignedInstanceSize() const {
    ASSERT(isRealized());
    return data()->ro()->instanceSize;
}

// objc-os.h

#  define WORD_MASK 7UL
static inline size_t word_align(size_t x) {
    return (x + WORD_MASK) & ~WORD_MASK;
}
```

- 探索`alloc`函数：调用`alloc`函数为`NSObject`对象分配开辟存储空间

```objective-c
// NSObject.mm
+ (id)alloc {
    return _objc_rootAlloc(self);
}

// Base class implementation of +alloc. cls is not nil.
// Calls [cls allocWithZone:nil].
id
_objc_rootAlloc(Class cls)
{
    return callAlloc(cls, false/*checkNil*/, true/*allocWithZone*/);
}

// Call [cls alloc] or [cls allocWithZone:nil], with appropriate 
// shortcutting optimizations.
static ALWAYS_INLINE id
callAlloc(Class cls, bool checkNil, bool allocWithZone=false)
{
#if __OBJC2__
    if (slowpath(checkNil && !cls)) return nil;
    if (fastpath(!cls->ISA()->hasCustomAWZ())) {
        return _objc_rootAllocWithZone(cls, nil);
    }
#endif
    // No shortcuts available.
    if (allocWithZone) {
        return ((id(*)(id, SEL, struct _NSZone *))objc_msgSend)(cls, @selector(allocWithZone:), nil);
    }
    return ((id(*)(id, SEL))objc_msgSend)(cls, @selector(alloc));
}

// objc-runtime-new.mm
id
_objc_rootAllocWithZone(Class cls, malloc_zone_t *zone __unused)
{
    // allocWithZone under __OBJC2__ ignores the zone parameter
    return _class_createInstanceFromZone(cls, 0, nil,
                                         OBJECT_CONSTRUCT_CALL_BADALLOC);
}

// objc-runtime-new.mm
static ALWAYS_INLINE id
_class_createInstanceFromZone(Class cls, size_t extraBytes, void *zone,
                              int construct_flags = OBJECT_CONSTRUCT_NONE,
                              bool cxxConstruct = true,
                              size_t *outAllocatedSize = nil)
{
    ASSERT(cls->isRealized());

    // Read class's info bits all at once for performance
    bool hasCxxCtor = cxxConstruct && cls->hasCxxCtor();
    bool hasCxxDtor = cls->hasCxxDtor();
    bool fast = cls->canAllocNonpointer();
    size_t size;

    size = cls->instanceSize(extraBytes);
	
  	...
}


// objc-runtime-new.h
size_t instanceSize(size_t extraBytes) const {
    if (fastpath(cache.hasFastInstanceSize(extraBytes))) {
        return cache.fastInstanceSize(extraBytes);
    }

    size_t size = alignedInstanceSize() + extraBytes;
    // CF requires all objects be at least 16 bytes.
    if (size < 16) size = 16;
    return size;
}
```



## 三、OC 对象的分类

OC对象主要可以分为三类：

- `instance`对象（实例对象）
- `class`对象（类对象）
- `meta-class`对象（元类对象）

### instance对象（实例对象）

我们在上述探究 `NSObject` 对象的本质过程中，探索其实就是 `instance` 对象。  `instance` 对象是通过类实例化创建出来的，每次调用 `alloc` 都会创建一个新的对象。

`instance` 对象在内存中存储的信息包括 **`isa` 指针和其他成员变量**。不包括任何方法。也就是说，方法的内存并不是存储到对象的内存中的。

### class对象（类对象）

- 类对象就是实例对象的类，为什么说他也是一个对象，因为类对象中也有一个  `isa` 指针

```objective-c
NSObject *obj1 = [[NSObject alloc] init];
NSObject *obj2 = [[NSObject alloc] init];

// 获取类对象的方法
Class objectClass1 = [obj1 class];
Class objectClass2 = [obj2 class];
// 传入实例对象返回类对象
Class objectClass3 = object_getClass(obj1);
Class objectClass4 = object_getClass(obj2);
Class objectClass5 = [NSObject class];

NSLog(@"%p %p %p %p %p", objectClass1, objectClass2, objectClass3, objectClass4, objectClass5);
// 0x7fff8d86e118 0x7fff8d86e118 0x7fff8d86e118 0x7fff8d86e118 0x7fff8d86e118
```

可以通过对象的class方法，类的class方法和runtime中`object_getClass`函数获取类对象。上述代码中，我们发现获取到的5个类对象的地址是相同的。这说明，**每个类在内存中，只有一个class对象**。

- 类对象在内存中存储的信息主要包括
  - isa指针
  - superclass指针
  - 类的属性信息，类的**对象方法**信息
  - 类的协议信息，**类的成员变量信息，注意不是成员变量的值**
  - ......

### meta-class对象

如何获取元类对象呢？获取元类对象，只能使用 `object_getClass` 函数获取，传入的参数是 `class`对象。

```objective-c
Class objectMetaClass = object_getClass([NSObject class]);
```

如何证明我们获取的是元类对象呢？其实runtime中提供了相应的API

```objective-c
NSLog(@"%d", c b
```

**每个类的内存中，也只有一个meta-class对象。**

meta-class对象和class对象的内存结构是一样的，但是用途不一样，换句话说，就是存储的内容是不一样的。meta-class对象存储的主要信息包括：

- isa指针
- superclass指针
- 类的**类方法信息**
- ......

也就是说，meta-class对象的内存结构中也包含类的属性信息但是里面存储的内容是`null`

> 注意：`[[NSObject class] class]; `获取的并不是元类对象而是类对象，可以通过`class_isMetaClass()`函数进行判断，返回的是NO。
>
> 也可以打印`[[NSObject class] class];`返回的对象地址和`[NSObject class];`返回的地址，可以发现两者是一样的。

## 四、isa 的指向

关于 isa 的指向用文字描述起来非常的绕，有一张非常经典的图如下：

![isa](https://user-images.githubusercontent.com/17879178/132787351-c529da34-2827-4eed-8cd9-ab334275dbfd.jpeg)

- 虚线代表 `isa` 的指向，实线代表 `superclass` 的指向
- `superclass` 不用说了该指针指向了其父类
- 如果是实例对象 `isa` 指向它的类对象，其类对象的 `isa` 指向了其元类对象

> 注意：上面的图片现在描述的已经不够准确了，随着苹果不断的优化，isa 已经不是直接指向类对象/元类对象了，而是通过 & mask 的值来找到类对象/元类对象了，苹果利用 union 和 位域的概念进行了优化。但是上图可以帮助我们更好的理解 isa 的指向。

通过了解到 `isa` 的指向，利用 OC 的动态性，在运行时可以通过动态添加类并修改 `isa` 的指向，其中 `KVO` 技术利用这点特性实现的。

