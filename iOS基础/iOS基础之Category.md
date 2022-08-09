## 一、简介

`Category` 是 Objective-C 2.0 之后添加的语言特性，`Category` 的主要作用是**为已经存在的类添加方法**，我们可以在不知道该类的实现源码的情况下使用 `Category` 为其添加额外的方法。

- 我们可以利用 `Category` 把类的实现分开在几个不同的文件中，这样可以减少单个文件的体积。可以把不同的功能组织到不同的 `Category` 里使功能单一化。可以由多个开发者共同完成一个类，只需各自创建该类的 `Category` 即可。可以按需加载想要的 `Category`，比如 `SDWebImage` 中 `UIImageView+WebCache` 和 `UIButton+WebCache`，根据不同需求加载不同的 `Category`
- 利用 `Category` 将私有方法公开化，直接调用某个类的私有方法时，编译器会报错，就可以创建一个该类的 `Category` ，在 `Category` 中声明这些私有方法，但不做实现。导入该 `Category` 的头文件就就可以正常调用私有方法了。

## 二、Extension 和 Category 对比

- `Extension` 是在**编译期**决定的，它就是类的一部分，在编译期和头文件里的 `@interface` 和 实现文件里的 `@implementation`形成一个完整的类，它伴随类的的产生而产生，随着类的消亡而消亡。`Extension` 一般用来隐藏类的私有信息，必须有类的源码才可以为一个类添加 `Extension`。所以无法为系统的类添加 `Extension`。
- `Category` 是在**运行期**决定的，`Category` 中可以添加实例方法，类方法，可以遵守协议，**可以添加属性**，**但是只生成 `setter` 和 `getter` 方法的声明，不生成实现，同样不生成带下划线的成员变量。**

## 三、Category 的本质

### 3.1 Category的基本使用

我们首先来看以下 `Category` 的基本使用：

```objective-c
// Person+Eat.h

#import "Person.h"

@interface Person (Eat) <NSCopying, NSCoding> // 遵守了2个协议

- (void)eatBread; // 声明实例方法

+ (void)eatFruit; // 声明类方法

@property (nonatomic, assign) int count; // 声明属性

@end

// Person+Eat.m

#import "Person+Eat.h"

@implementation Person (Eat)

- (void)eatBread {
    NSLog(@"eatBread");
}

+ (void)eatFruit {
    NSLog(@"eatFruit");
}

@end
```

### 3.2 编译期的 Category 

我们通过 `clang` 编译器来观察一下在编译期 `Category` 的结构

```shell
xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc MyClass.m -o MyClass-arm64.cpp
```

编译之后，我们可以发现 `Category` 的本质是结构体 `category_t`，无论我们创建了多少个 `Category` 最终都会生成 `category_t` 这个结构体，并且 `category_t` 中的方法、属性、协议都是存储在这个结构体里的。**也就是说在编译期，分类中成员是不会和类合并在一起的**。

```c
struct category_t {
    const char *name;															// 类的名字
    classref_t cls;																// 关联的类
    struct method_list_t *instanceMethods;				// 实例方法列表
    struct method_list_t *classMethods;						// 类方法列表
    struct protocol_list_t *protocols;						// 协议列表（遵守了多少协议）
    struct property_list_t *instanceProperties;		// 属性列表
};
```

**从 `category_t` 的定义中可以发现，我们可以添加实例方法，添加类方法，可以实现协议，可以添加属性。**

**但是，不可以添加实例变量，实例变量可以利用 runtime 的关联对象变相的实现**

我们继续研究下面的编译后的代码：

```cpp
static struct /*_method_list_t*/ { // 实例方法列表结构体
	unsigned int entsize;  // sizeof(struct _objc_method)
	unsigned int method_count;
	struct _objc_method method_list[1];
} _OBJC_$_CATEGORY_INSTANCE_METHODS_Person_$_Eat __attribute__ ((used, section ("__DATA,__objc_const"))) = {
	sizeof(_objc_method),
	1,
	{{(struct objc_selector *)"eatBread", "v16@0:8", (void *)_I_Person_Eat_eatBread}}
};

static struct /*_method_list_t*/ { // 类方法列表结构体
	unsigned int entsize;  // sizeof(struct _objc_method)
	unsigned int method_count;
	struct _objc_method method_list[1];
} _OBJC_$_CATEGORY_CLASS_METHODS_Person_$_Eat __attribute__ ((used, section ("__DATA,__objc_const"))) = {
	sizeof(_objc_method),
	1,
	{{(struct objc_selector *)"eatFruit", "v16@0:8", (void *)_C_Person_Eat_eatFruit}}
};

static struct /*_protocol_list_t*/ { // 协议列表结构体
	long protocol_count;  // Note, this is 32/64 bit
	struct _protocol_t *super_protocols[2];
} _OBJC_CATEGORY_PROTOCOLS_$_Person_$_Eat __attribute__ ((used, section ("__DATA,__objc_const"))) = {
	2,
	&_OBJC_PROTOCOL_NSCopying,
	&_OBJC_PROTOCOL_NSCoding
};

static struct /*_prop_list_t*/ { // 属性列表结构体
	unsigned int entsize;  // sizeof(struct _prop_t)
	unsigned int count_of_properties;
	struct _prop_t prop_list[1];
} _OBJC_$_PROP_LIST_Person_$_Eat __attribute__ ((used, section ("__DATA,__objc_const"))) = {
	sizeof(_prop_t),
	1,
	{{"count","Ti,N"}}
};

// category 的结构体
static struct _category_t _OBJC_$_CATEGORY_Person_$_Eat __attribute__ ((used, section ("__DATA,__objc_const"))) = 
{
	"Person",
	0, // &OBJC_CLASS_$_Person,
	(const struct _method_list_t *)&_OBJC_$_CATEGORY_INSTANCE_METHODS_Person_$_Eat,
	(const struct _method_list_t *)&_OBJC_$_CATEGORY_CLASS_METHODS_Person_$_Eat,
	(const struct _protocol_list_t *)&_OBJC_CATEGORY_PROTOCOLS_$_Person_$_Eat,
	(const struct _prop_list_t *)&_OBJC_$_PROP_LIST_Person_$_Eat,
};
```

- 首先看一下 `_OBJC_$_CATEGORY_Person_$_Eat` 结构体变量中的值，就是分别对应 `category_t` 的成员，第1个成员就是类名，因为我们声明了实例方法，类方法，遵守了协议，定义了属性，所以我们的结构体变量中这些都会有值。
- `_OBJC_$_CATEGORY_INSTANCE_METHODS_Person_$_Eat` 结构体表示实例方法列表，里面包含了 `eatBread` 实例方法
- `_OBJC_$_CATEGORY_CLASS_METHODS_Person_$_Eat` 结构体包含了 `eatFruit` 类方法
- `_OBJC_CATEGORY_PROTOCOLS_$_Person_$_Eat` 结构体包含了 `NSCoping` 和 `NSCoding` 协议
- `_OBJC_$_PROP_LIST_Person_$_Eat` 结构体包含了 `count` 属性

### 3.3 运行期的 Category

在研究完编译时期的 `Category` 后，我们进而研究运行时期的 `Category`

在 `objc-runtime-new.mm` 的源码中，我们可以最终找到如何将 `Category` 中的方法列表，属性列表，协议列表添加到类中。

```cpp
static void
attachCategories(Class cls, const locstamped_category_t *cats_list, uint32_t cats_count,
                 int flags)
{
    if (slowpath(PrintReplacedMethods)) {
        printReplacements(cls, cats_list, cats_count);
    }
    if (slowpath(PrintConnecting)) {
        _objc_inform("CLASS: attaching %d categories to%s class '%s'%s",
                     cats_count, (flags & ATTACH_EXISTING) ? " existing" : "",
                     cls->nameForLogging(), (flags & ATTACH_METACLASS) ? " (meta)" : "");
    }

    /*
     * Only a few classes have more than 64 categories during launch.
     * This uses a little stack, and avoids malloc.
     *
     * Categories must be added in the proper order, which is back
     * to front. To do that with the chunking, we iterate cats_list
     * from front to back, build up the local buffers backwards,
     * and call attachLists on the chunks. attachLists prepends the
     * lists, so the final result is in the expected order.
     */
    constexpr uint32_t ATTACH_BUFSIZ = 64;
    method_list_t   *mlists[ATTACH_BUFSIZ];
    property_list_t *proplists[ATTACH_BUFSIZ];
    protocol_list_t *protolists[ATTACH_BUFSIZ];

    uint32_t mcount = 0;
    uint32_t propcount = 0;
    uint32_t protocount = 0;
    bool fromBundle = NO;
    bool isMeta = (flags & ATTACH_METACLASS);
    auto rwe = cls->data()->extAllocIfNeeded();

  	// 遍历所有的 category
    for (uint32_t i = 0; i < cats_count; i++) {
        auto& entry = cats_list[i];

        method_list_t *mlist = entry.cat->methodsForMeta(isMeta);
        if ( ) {
            if (mcount == ATTACH_BUFSIZ) {
                prepareMethodLists(cls, mlists, mcount, NO, fromBundle);
              	// 方法添加类中
                rwe->methods.attachLists(mlists, mcount);
                mcount = 0;
            }
            mlists[ATTACH_BUFSIZ - ++mcount] = mlist;
            fromBundle |= entry.hi->isBundle();
        }

        property_list_t *proplist =
            entry.cat->propertiesForMeta(isMeta, entry.hi);
        if (proplist) {
            if (propcount == ATTACH_BUFSIZ) {
              	// 属性添加到类中
                rwe->properties.attachLists(proplists, propcount);
                propcount = 0;
            }
            proplists[ATTACH_BUFSIZ - ++propcount] = proplist;
        }

        protocol_list_t *protolist = entry.cat->protocolsForMeta(isMeta);
        if (protolist) {
            if (protocount == ATTACH_BUFSIZ) {
              	// 协议添加到类中
                rwe->protocols.attachLists(protolists, protocount);
                protocount = 0;
            }
            protolists[ATTACH_BUFSIZ - ++protocount] = protolist;
        }
    }

    if (mcount > 0) {
        prepareMethodLists(cls, mlists + ATTACH_BUFSIZ - mcount, mcount, NO, fromBundle);
        rwe->methods.attachLists(mlists + ATTACH_BUFSIZ - mcount, mcount);
        if (flags & ATTACH_EXISTING) flushCaches(cls);
    }

    rwe->properties.attachLists(proplists + ATTACH_BUFSIZ - propcount, propcount);

    rwe->protocols.attachLists(protolists + ATTACH_BUFSIZ - protocount, protocount);
}
```

- `rwe->methods.attachLists(mlists, mcount);`
- `rwe->protocols.attachLists(protolists, protocount);`
- `rwe->properties.attachLists(proplists, propcount);`

以上三个函数就是把 `category` 中的方法、属性和协议列表添加到类中的函数。

继续查看 `attchLists` 函数的实现：

```c
void attachLists(List* const * addedLists, uint32_t addedCount) {
    if (addedCount == 0) return;

    if (hasArray()) {
        // many lists -> many lists
        uint32_t oldCount = array()->count;
        uint32_t newCount = oldCount + addedCount;
        setArray((array_t *)realloc(array(), array_t::byteSize(newCount)));
        array()->count = newCount;
      	// 向后移动出空间
        memmove(array()->lists + addedCount, array()->lists, 
                oldCount * sizeof(array()->lists[0]));
      	// 将新的方法复制到新的空间中
        memcpy(array()->lists, addedLists, 
               addedCount * sizeof(array()->lists[0]));
    }
    else if (!list  &&  addedCount == 1) {
        // 0 lists -> 1 list
        list = addedLists[0];
    } 
    else {
        // 1 list -> many lists
        List* oldList = list;
        uint32_t oldCount = oldList ? 1 : 0;
        uint32_t newCount = oldCount + addedCount;
        setArray((array_t *)malloc(array_t::byteSize(newCount)));
        array()->count = newCount;
        if (oldList) array()->lists[addedCount] = oldList;
        memcpy(array()->lists, addedLists, 
               addedCount * sizeof(array()->lists[0]));
    }
}
```

- 在这段源码中，主要关注2个函数 `memmove` 和 `memcpy`。
- `memmove` 函数的作用是移动内存，将之前的内存向后移动，将原来的方法列表往后移
- `memcpy` 函数的作用是内存的拷贝，将 `Category` 中的方法列表复制到上一步移出来的位置。

从上述源码中，可以发现 `Category` 的方法**并没有替换原来类已有的方法**，如果 `Category` 和原来类中都有某个同名方法，只不过 `Category` 中的方法被放到了新方法列表的前面，在运行时查找方法的时候，一旦找到该方法，就不会向下继续查找了，产生了 `Category` 会覆盖原类方法的假象。

> 所以我们在 `Category` 定义方法的时候通常都要加上前缀，以避免意外的重名把类本身的方法”覆盖“掉。

- 如果多个 `Category` 中存在同名的方法，运行时最终调用哪个方法是由编译器决定的，**最后一个参与编译的方法将会先被调用**。

## 四、+load 方法

接下来研究一下类和 `Category` 中的 `+load` 方法的调用，先看以下的代码：

```objective-c
// Person.h
@interface Person : NSObject

+ (void)test;

@end

// Person.m
@implementation Person

+ (void)load {
    NSLog(@"Person +load");
}

+ (void)test {
    NSLog(@"Person +test");
}

@end
  
// Person+Test1.m
@implementation Person (Test1)

+ (void)load {
    NSLog(@"Person (Test1) +load");
}

+ (void)test {
    NSLog(@"Person (Test1) +test");
}

@end
  
// Person+Test2.m
@implementation Person (Test2)

+ (void)load {
    NSLog(@"Person (Test2) +load");
}

+ (void)test {
    NSLog(@"Person (Test2) +test");
}

@end

  
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        [Person test];
      
    }
    return 0;
}

// 打印结果：
Person +load
Person (Test1) +load
Person (Test2) +load
Person (Test2) +test
```

- 通过打印结果发现， `+load` 方法会调用3次，而 `test` 方法只会调用1次，结论好像和上面研究的结果不太一样，之前的研究结论是相同名称的方法只会调用分类最后编译的分类，这说明 `+load` 方法和 `test` 方法的调用本质是不一样的。具体是原因是什么呢？只能通过源码来探究一下了

源码中 `call_load_methods` 函数来加载类中的 `+load` 方法的：

```c
void call_load_methods(void)
{
    static bool loading = NO;
    bool more_categories;

    loadMethodLock.assertLocked();

    // Re-entrant calls do nothing; the outermost call will finish the job.
    if (loading) return;
    loading = YES;

    void *pool = objc_autoreleasePoolPush();

    do {
        // 1. Repeatedly call class +loads until there aren't any more
        while (loadable_classes_used > 0) {
          	// 调用类的 load 方法
            call_class_loads();
        }

        // 2. Call category +loads ONCE
      	// 调用 category 的 load 方法
        more_categories = call_category_loads();

        // 3. Run more +loads if there are classes OR more untried categories
    } while (loadable_classes_used > 0  ||  more_categories);

    objc_autoreleasePoolPop(pool);

    loading = NO;
}
```

- 从这个函数中，我们可以看到这个 `do-while` 循环，首先是通过 `call_class_loads` 函数来加载类中的 `+load` 方法

```c
static void call_class_loads(void)
{
    int i;
    
    // Detach current loadable list.
    struct loadable_class *classes = loadable_classes;
    int used = loadable_classes_used;
    loadable_classes = nil;
    loadable_classes_allocated = 0;
    loadable_classes_used = 0;
    
    // Call all +loads for the detached list.
    for (i = 0; i < used; i++) {
        Class cls = classes[i].cls;
        load_method_t load_method = (load_method_t)classes[i].method;
        if (!cls) continue; 

        if (PrintLoading) {
            _objc_inform("LOAD: +[%s load]\n", cls->nameForLogging());
        }
      	// 调用 load
        (*load_method)(cls, @selector(load));
    }
    
    // Destroy the detached list.
    if (classes) free(classes);
}
```

- 从 `call_class_loads` 函数中，可以发现通过 `load_method` 函数指针找到 `load` 方法并直接调用

当调用完类的 `load` 方法，会调用 `call_category_loads` 分类的 `load` 方法。

```c
static bool call_category_loads(void)
{
    int i, shift;
    bool new_categories_added = NO;
    
    // Detach current loadable list.
    struct loadable_category *cats = loadable_categories;
    int used = loadable_categories_used;
    int allocated = loadable_categories_allocated;
    loadable_categories = nil;
    loadable_categories_allocated = 0;
    loadable_categories_used = 0;

    // Call all +loads for the detached list.
    for (i = 0; i < used; i++) {
        Category cat = cats[i].cat;
        load_method_t load_method = (load_method_t)cats[i].method;
        Class cls;
        if (!cat) continue;

        cls = _category_getClass(cat);
        if (cls  &&  cls->isLoadable()) {
            if (PrintLoading) {
                _objc_inform("LOAD: +[%s(%s) load]\n", 
                             cls->nameForLogging(), 
                             _category_getName(cat));
            }
            (*load_method)(cls, @selector(load));
            cats[i].cat = nil;
        }
    }

    // Compact detached list (order-preserving)
    shift = 0;
    for (i = 0; i < used; i++) {
        if (cats[i].cat) {
            cats[i-shift] = cats[i];
        } else {
            shift++;
        }
    }
    used -= shift;

    // Copy any new +load candidates from the new list to the detached list.
    new_categories_added = (loadable_categories_used > 0);
    for (i = 0; i < loadable_categories_used; i++) {
        if (used == allocated) {
            allocated = allocated*2 + 16;
            cats = (struct loadable_category *)
                realloc(cats, allocated *
                                  sizeof(struct loadable_category));
        }
        cats[used++] = loadable_categories[i];
    }

    // Destroy the new list.
    if (loadable_categories) free(loadable_categories);

    // Reattach the (now augmented) detached list. 
    // But if there's nothing left to load, destroy the list.
    if (used) {
        loadable_categories = cats;
        loadable_categories_used = used;
        loadable_categories_allocated = allocated;
    } else {
        if (cats) free(cats);
        loadable_categories = nil;
        loadable_categories_used = 0;
        loadable_categories_allocated = 0;
    }

    if (PrintLoading) {
        if (loadable_categories_used != 0) {
            _objc_inform("LOAD: %d categories still waiting for +load\n",
                         loadable_categories_used);
        }
    }

    return new_categories_added;
}
```

- 该函数也是通过 `load_method` 函数指针直接调用分类中的 `load` 方法。

通过上面的源码的分析，我们可以得出以下结论：

- `load` 方法的调用顺序问题，首先是调用类中的 `load` 方法并且和编译的顺序没有任何关系，然后是调用分类中的 `load` 方法，分类中的 `load` 方法是按照编译的顺序进行调用
- 解释了为什么之前的例子中 `Person` 类和分类中的 `load` 方法为什么调用了3次，而 `test` 方法只调用1次。因为 `load` 方法通过函数指针找到函数的内存地址进行的直接调用，而 `+test` 方法通过 `isa` 指针最终找到元类对象中的类方法列表进行的调用（也就是走的消息发送的流程），二者调用的本质不一样。

接下来研究一下存在继承的情况下的 `load` 方法的调用，创建 `Student` 类继承自 `Person` 类，并创建2个分类

```objective-c
// Student.m
@implementation Student

+ (void)load {
    NSLog(@"Student +load");
}

@end
  
// Student+Test1.m
@implementation Student (Test1)
+ (void)load {
    NSLog(@"Student (Test1) +load");
}
@end
  
// Student+Test1.m
@implementation Student (Test2)
+ (void)load {
    NSLog(@"Student (Test2) +load");
}
@end
  
// 打印结果
Person +load
Student +load
Student (Test2) +load
Person (Test2) +load
Student (Test1) +load
Person (Test1) +load
```

- 根据打印结果先调用父类的 `load` 方法，再调用子类的 `load` 方法，然后再调用分类中的 `load` 方法

还是从 `runtime` 的源码中进行分析，在调用 `call_category_loads` 函数之前，调用了 `prepare_load_methods` 函数

```c
void prepare_load_methods(const headerType *mhdr)
{
    size_t count, i;

    runtimeLock.assertLocked();

    classref_t const *classlist = 
        _getObjc2NonlazyClassList(mhdr, &count);
    for (i = 0; i < count; i++) {
        schedule_class_load(remapClass(classlist[i]));
    }

    category_t * const *categorylist = _getObjc2NonlazyCategoryList(mhdr, &count);
    for (i = 0; i < count; i++) {
        category_t *cat = categorylist[i];
        Class cls = remapClass(cat->cls);
        if (!cls) continue;  // category for ignored weak-linked class
        if (cls->isSwiftStable()) {
            _objc_fatal("Swift class extensions and categories on Swift "
                        "classes are not allowed to have +load methods");
        }
        realizeClassWithoutSwift(cls, nil);
        ASSERT(cls->ISA()->isRealized());
        add_category_to_loadable_list(cat);
    }
}

```

该函数中主要根据类的列表循环调用 `schedule_class_load` 函数

```c
static void schedule_class_load(Class cls)
{
    if (!cls) return;
    ASSERT(cls->isRealized());  // _read_images should realize

    if (cls->data()->flags & RW_LOADED) return;

    // Ensure superclass-first ordering
    schedule_class_load(cls->superclass);

    add_class_to_loadable_list(cls);
    cls->setInfo(RW_LOADED); 
}
```

- 从`schedule_class_load` 函数是递归调用，首先查找父类调用，保证父类的 `load` 方法。通过源码就印证了我们之前的打印结果。
- 而分类的 `load` 方法调用没有先调用父类的说法了，而是按照编译的顺序，先编译先调用

如果再创建一个类和 `Person` 类没有任何继承关系，那么 `load` 方法的调用也是按照编译顺序调用的，先编译先调用。

## 五、+Initialize 方法

`initialize` 方法和 `load` 方法非常容易混淆。我们将上面 `Person` 的例子做一个改造，将 `load` 方法都改为 `initailize` 方法来查看一下打印的结果：

```objective-c
// Person.m
@implementation Person

+ (void)initialize {
    NSLog(@"Person +initialize");
}

@end

// Person+Test1.m
@implementation Person (Test1)

+ (void)initialize {
    NSLog(@"Person (Test1) +initialize");
}

@end
  
// Person+Test2.m
@implementation Person (Test2)

+ (void)initialize {
    NSLog(@"Person (Test2) +initialize");
}

@end
  
// Student.m
@implementation Student

+ (void)initialize {
    NSLog(@"Student +initialize");
}

@end

// main 函数
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [Student alloc];
    }
    return 0;
}

// 打印结果
Person (Test1) +initialize
Student +initialize
```

- 在 `main` 函数中我们只调用了 `Student` 的 `alloc` 方法，发现打印结果有2个，如果我们注释掉 `main` 函数中，`Student` 的 `alloc` 方法的调用，我们会发现，控制台什么都不会打印。此时我们得出一个结论：**`initilize` 方法是在类第一次接收到消息时才会调用的**。
- 第2个现象是，我们只对 `Student` 发送了消息，发现它的父类 `Person` 的 `initilize` 方法也会被调用，而且是调用的是分类中的 `initilize` 方法。这说明 `initilize` 方法是通过消息机制进行调用的，也就是通过 `isa` 找到类对象/元类对象进行方法的调用，因为分类的存在所以只会调用分类中的方法。

接下来我们通过源码来探究一下本质的问题：

```c
Class class_initialize(Class cls, id obj)
{
    runtimeLock.lock();
    return initializeAndMaybeRelock(cls, obj, runtimeLock, false);
}

static Class initializeAndMaybeRelock(Class cls, id inst,
                                      mutex_t& lock, bool leaveLocked)
{
    lock.assertLocked();
    ASSERT(cls->isRealized());

    if (cls->isInitialized()) {
        if (!leaveLocked) lock.unlock();
        return cls;
    }

    // Find the non-meta class for cls, if it is not already one.
    // The +initialize message is sent to the non-meta class object.
    Class nonmeta = getMaybeUnrealizedNonMetaClass(cls, inst);

    // Realize the non-meta class if necessary.
    if (nonmeta->isRealized()) {
        // nonmeta is cls, which was already realized
        // OR nonmeta is distinct, but is already realized
        // - nothing else to do
        lock.unlock();
    } else {
        nonmeta = realizeClassMaybeSwiftAndUnlock(nonmeta, lock);
        // runtimeLock is now unlocked
        // fixme Swift can't relocate the class today,
        // but someday it will:
        cls = object_getClass(nonmeta);
    }

    // runtimeLock is now unlocked, for +initialize dispatch
    ASSERT(nonmeta->isRealized());
    initializeNonMetaClass(nonmeta);

    if (leaveLocked) runtimeLock.lock();
    return cls;
}
```

- `class_initialize` 函数调用的是 `initializeAndMaybeRelock` 函数，这个函数中关注 `initializeNonMetaClass` 函数

```c
void initializeNonMetaClass(Class cls)
{
    ASSERT(!cls->isMetaClass());

    Class supercls;
    bool reallyInitialize = NO;

    // Make sure super is done initializing BEFORE beginning to initialize cls.
    // See note about deadlock above.
    supercls = cls->superclass;
    if (supercls  &&  !supercls->isInitialized()) {
        initializeNonMetaClass(supercls);
    }
    
 			...
#endif
        {
            callInitialize(cls);

      ...
}
  
void callInitialize(Class cls)
{
    ((void(*)(Class, SEL))objc_msgSend)(cls, @selector(initialize));
    asm("");
}
```

- 从上面的函数中，我们发现 `initilize` 函数时是通过递归，先调用父类的 `initilize` 函数，最后来调用 `callInitialize` 函数，而 `callInitialize` 函数内部调用了 `objc_msgSend` 函数的。

通过源码，解释了 `initilize` 方法是先调用父类的再调用子类的。

> 最后注意一点：如果子类没有实现 `initilize` 方法，子类在接收到消息的时候，父类的 `initilize` 方法会调用多次的。
>
> 原因是：当父类 `initilize` 方法调用完毕，而子类没有 `initilize` 方法，子类会通过 `superclass` 指针去父类中查找 `initilize` 方法发现父类中存在，就会调用父类的 `initilize` 方法，但不代表父类被初始化两次。



##  六、Category 和 关联对象

因为 `Category` 的结构体中是无法添加实例变量的，此时我们可以借助 `runtime` 的关联对象来实现。

如果我们只是在 `Category` 中添加属性，默认是只会生成 `getter`  和 `setter` 方法的声明，不会生成 `getter` 和 `setter` 方法的实现和成员变量，所以我们想要使用定义的属性进行取值和赋值的操作，会因为找不到方法实现而崩溃。

可以通过关联对象的方式，间接实现取值和赋值的功能：

```objective-c
// Person+Test.h 
@interface Person (Test)

@property (nonatomic, copy) NSString *name;

@end

// Person+Test.m
@implementation Person (Test)

- (void)setName:(NSString *)name {
    objc_setAssociatedObject(self, @selector(name), name, OBJC_ASSOCIATION_COPY);
}

- (NSString *)name {
    return objc_getAssociatedObject(self, @selector(name));
}

@end
```

- 首先是在 `category` 的声明文件中定义一个属性，在实现文件中手动实现 `getter` 和 `setter` 方法，在 `getter` 和 `setter` 方法的内部使用关联对象。

- `objc_setAssociatedObject` 函数需要传入4个参数
  - 第一个参数是被关联的对象
  - 第二个参数是需要传入一个地址，`const void *` 类型，目的是通过这个地址来将设置的值进行一个映射
  - 第三个参数是要设置的值
  - 第四个参数类似定义属性的关键字，主要是进行内存的管理
- `objc_getAssociatedObject` 函数传入2个参数
  - 第一个参数是被关联的对象
  - 第二个参数是传入一个地址，通过这个地址获取之前设置的值，所以就要保证和 `objc_setAssociatedObject`第二个参数保持一致。

但是关联对象存在什么地方呢？是不是存在对象的内存中呢？对象销毁时关联对象如何处理呢？

我们在 `objc-references.mm` 文件中可以找到 `_object_get_associative_reference` 和 `_object_set_associative_reference` 函数，我们可以发现关联对象是通过 `AssociationsManager` 管理的。

而在 `AssociationsManager`中通过 `AssociationsHashMap` 来存储所有的关联对象的。而 `AssociationsHashMap` 的 `key` 是被关联对象的指针地址，对应的 `value` 是一个 `ObjectAssociationMap`，而 `ObjectAssociationMap` 对应的 `key` 为一个 `const void *` 的指针而 `value` 对应的是 `ObjcAssociation`，在 `ObjcAssociation` 中又包含两个成员分别为 `_policy` 和 `_value`。到此为止，我们就搞清楚关联对象的本质了。

如果我们想要删除某个关联对象的值，只需要在 `objc_setAssociatedObject`函数中将对应`key`的`value`传为 `nil`，就会对某个关联对象值进行擦除。

还有一个疑惑那就是当对象销毁时，关联对象会怎么处理呢？

在对象的销毁源码里：在 `objc-runtime-new.mm` 文件中

会判断对象中是否包含关联对象，如果包含，就将关联对象移除掉。所以在对象销毁时，和它关联的关联对象也会被销毁掉。

```cpp
void *objc_destructInstance(id obj) 
{
    if (obj) {
        // Read all of the flags at once for performance.
        bool cxx = obj->hasCxxDtor();
        bool assoc = obj->hasAssociatedObjects();

        // This order is important.
        if (cxx) object_cxxDestruct(obj);
      
        if (assoc) _object_remove_assocations(obj);
        obj->clearDeallocating();
    }

    return obj;
}
```

