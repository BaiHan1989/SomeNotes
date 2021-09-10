## 一、前言

`copy` 这个英文单词，让我第一个想起的是 copy 忍者卡卡西。个人非常喜欢卡卡西，和谁对战都是五五开的上忍。`copy` 翻译成中文就是复制的意思，为什么我们想要复制呢？我觉得原因有下面几点：

1. 复制更快，重复的东西通过复制，可以快速得到一个一模一样的东西，比如说一个文件，一段文字，一个忍术什么的。
2. 更改复制出来的东西，不会影响原来的文件、文字，忍术什么的，这是我们的目的

那么回到 `iOS` 开发，其实类比到生活中也差不多。我们的目的是修改复制出来的东西，不希望影响原来的内容。

针对 `copy` 就会引出一些面试题：

1. 定义一个 `NSString` 类型的属性时，通常使用 `copy` 关键字，可以使用 `strong` 关键字修饰吗？如果可以，什么时候使用 `strong` 修饰，什么时候使用 `copy` 修饰？
2. 定义一个 `NSMutableArray` 属性时，关键字使用 `copy`，像 `NSMutableArray` 中添加元素会发生什么现象？
3. 涉及到深拷贝，浅拷贝的，`NSString` 、`NSMutableString`、 `NSArray`、 `NSMutableArray`、 `NSDictionary` `NSMutableDictionary` 调用 `copy` 方法或者 `mutableCopy` 方法，是深拷贝还是浅拷贝？

等等...

下面我们就来探究一下 `copy`

## 二、实战

### 2.1  NSString

- 在写案例之前，我们应该明确一点，`NSString` 这个类代表**不可变字符串**。不可变意味着创建出来的字符串对象不可以被修改
- 创建一个字符串对象 `test`，`str1` 指向字符串对象
- `str1` 调用 `copy` 方法，`str2` 指向 `copy` 出来的对象
- `str1` 调用 `mutableCopy` 方法，`str3` 指向 `mutableCopy` 出来的对象

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *str1 = @"test";
    NSString *str2 = [str1 copy];
    NSMutableString *str3 = [str1 mutableCopy];
    
    NSLog(@"\n str1 -> %@ \n str2 -> %@ \n str3 -> %@", str1, str2, str3);
    NSLog(@"\n str1 -> %p \n str2 -> %p \n str3 -> %p", str1, str2, str3);
    
}
// 打印结果：
2020-06-04 22:47:42.843279+0800 05_copy[34618:3042446] 
 str1 -> test 
 str2 -> test 
 str3 -> test
2020-06-04 22:47:42.843496+0800 05_copy[34618:3042446] 
 str1 -> 0x10c9a0020 
 str2 -> 0x10c9a0020 
 str3 -> 0x600001836fa0
```

从打印结果可以看出：

- 无论是调用 `copy` 还是 `mutaleCopy` 方法都成功复制了 `test` 这个文本
- 从打印内存地址可以看出 `str1` 和 `str2` 都指向了同一个对象，而 `str3` 则指向了另外一个对象。

本质如图：

<img src="/Users/bh/Documents/我的文章/iOS底层原理/把copy聊透/image-20210531162213159.png" alt="image-20210531162213159" style="zoom:50%;" />

- `str1` 和 `st2` 都指向了同一个对象，`str3` 指向了另外一个对象。
- 为什么会出现这样的现象呢？因为正常情况下调用 `copy` 方法会返回一个**不可变对象**，而调用 `mutableCopy` 方法会返回一个**可变对象**。
- 返回不可变对象，就意味着无法修改，所以 `copy` 执行完毕之后，完全可以指向之前的对象，反正没办法进行修改，这样反而节省了内存空间。
- 返回可变对象，就意味着我们有修改字符串的需求，只有创建新的对象，修改字符串的时候才不会影响之前字符串的值。
- 使用 `NSString` 创建的对象，调用 `copy` 方法不会创建新的对象，只是指针的拷贝，属于浅拷贝。而调用 `mutableCopy` 方法会创建一个与之前内容一样的新的对象，但内存不同，属于深拷贝。

### 2.2 NSMutableString

- 创建一个可变字符串对象，内容是 `test`，用 `str1` 指向该对象
- `str1` 调用 `copy` 方法，使用 `str2` 指向返回的对象
- `str1` 调用 `mutableCopy` 方法，使用 `str3` 指向返回的对象

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableString *str1 = [[NSMutableString alloc] initWithString:@"test"];
    NSString *str2 = [str1 copy];
    NSMutableString *str3 = [str1 mutableCopy];

    NSLog(@"\n str1 -> %@ \n str2 -> %@ \n str3 -> %@", str1, str2, str3);
    NSLog(@"\n str1 -> %p \n str2 -> %p \n str3 -> %p", str1, str2, str3);
}

// 打印结果：
2020-06-05 12:16:42.174359+0800 05_copy[35192:3110215] 
 str1 -> test 
 str2 -> test 
 str3 -> test
2020-06-05 12:16:42.174536+0800 05_copy[35192:3110215] 
 str1 -> 0x600003d282d0 
 str2 -> 0xbf8fdf3650605176 
 str3 -> 0x600003d28270
```

结果分析：

- 毫无疑问，`st1` 和 `str2` 和 `str3` 的内容都是 `test`，内容成功复制
- 但是，三个指针存储的内存地址不同，说明产生了三个不同的对象

画图分析：

<img src="/Users/bh/Documents/我的文章/iOS底层原理/把copy聊透/image-20210531162851567.png" alt="image-20210531162851567" style="zoom:50%;" />

- `st1` 是指向的是可变字符串，可以进行修改
- `str1` 调用 `copy` 方法会重新创建一个新的不可变字符串，是深拷贝，因为当 `str1` 进行修改的时候，`str2` 中的值不会受到任何的影响
- `str1` 调用 `mutableCopy` 方法会创建一个新的可以变字符串，那么就可以对这个可变字符串进行修改，同样不影响 `str1` 和 `str2`，是深拷贝。并且三者互不影响。

### 2.3 NSArray和NSMutableArray

#### 2.3.1 NSArray

- 操作和上面 `NSString` 类似，就不再说明了，直接看代码

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *array1 = @[@"a", @"b", @"c"];
    NSArray *array2 = [array1 copy];
    NSMutableArray *array3 = [array1 mutableCopy];
    
    NSLog(@"\n array1 -> %@ \n array2 -> %@ \n array3 -> %@", array1, array2, array3);
    NSLog(@"\n array1 -> %p \n array2 -> %p \n array3 -> %p", array1, array2, array3);
}
// 打印结果：
2020-06-05 12:32:17.303200+0800 05_copy[35231:3117262] 
 array1 -> (
    a,
    b,
    c
) 
 array2 -> (
    a,
    b,
    c
) 
 array3 -> (
    a,
    b,
    c
)
2020-06-05 12:32:17.303393+0800 05_copy[35231:3117262] 
 array1 -> 0x600003a0c360 
 array2 -> 0x600003a0c360 
 array3 -> 0x600003a0c0f0
```

打印结果分析：

- 从数组的内容角度看，数组中的内容都成功被拷贝
- 从`array1` 、`array2` 和 `array3` 存储的地址值来看，调用 `copy` 方法进行了浅拷贝，而调用 `mutableCopy` 方法是深拷贝。也就是说，修改`array4`里面的值不会影响`array1` 和 `array2`

#### 2.3.2 NSMutableArray

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *array1 = [[NSMutableArray alloc] initWithObjects:@"a", @"b", @"c", nil];
    NSArray *array2 = [array1 copy];
    NSMutableArray *array3 = [array1 mutableCopy];
    
    NSLog(@"\n array1 -> %@ \n array2 -> %@ \n array3 -> %@", array1, array2, array3);
    NSLog(@"\n array1 -> %p \n array2 -> %p \n array3 -> %p", array1, array2, array3);
}
// 打印结果：
2020-06-05 12:37:57.830060+0800 05_copy[35251:3120031] 
 array1 -> (
    a,
    b,
    c
) 
 array2 -> (
    a,
    b,
    c
) 
 array3 -> (
    a,
    b,
    c
)
2020-06-05 12:37:57.830295+0800 05_copy[35251:3120031] 
 array1 -> 0x60000378d6e0 
 array2 -> 0x60000378d950 
 array3 -> 0x60000378d9b0
```

结果分析：

- 无论调用 `copy` 还是 `mutableCopy` 方法都是深拷贝

我们可以得出一些结论：

在 `OC` 中，其实还有很多类似的类比如`NSDictionary`    `NSMutableDictionary`    `NSSet`    `NSMutableSet`结论都是一样的。可以自己去敲一段代码来验证。常用的我总结如下表：

|                     |           copy           |           mutableCopy           |
| ------------------- | :----------------------: | :-----------------------------: |
| NSString            |   返回NSString、浅拷贝   |   返回NSMutableString、深拷贝   |
| NSMutableString     |   返回NSString、深拷贝   |   返回NSMutableString、深拷贝   |
| NSArray             |   返回NSArray、浅拷贝    |   返回NSMutableArray、深拷贝    |
| NSMutableArray      |   返回NSArray、深拷贝    |   返回NSMutableArray、深拷贝    |
| NSDictionary        | 返回NSDictionary、浅拷贝 | 返回NSMutableDictionary、深拷贝 |
| NSMutableDictionary | 返回NSDictionary、深拷贝 | 返回NSMutableDictionary、深拷贝 |



## 三、其他问题

上面已经讲清楚了，`copy` 和 `mutableCopy` 针对于不同的类返回结果以及是否产生新的对象做了分析和总结。

还遗留了点问题

1. 在一个中类定义一个 `NSString` 属性的时候，`NSString` 通常定义为 `copy` 定义成 `strong` 行不行？如果两者都行，开发中该使用哪一个？
2. 定义一个`NSMutableArray` 、`NSMutableString`、 `NSMutableDictionary`的属性，能不能用`copy`，会不会有什么问题？

### 3.1 问题1

- 如下代码打印结果是什么？如果把定义属性的`copy` 修改成 `strong`，那么打印结果又是什么呢?

```objective-c
@interface ViewController ()
@property (nonatomic, copy) NSString *str;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableString *mStr = [[NSMutableString alloc] initWithString:@"test"];
    self.str = mStr;
    [mStr appendString:@"haha"];
    NSLog(@"mStr -> %@", mStr);
    NSLog(@"self.str -> %@", self.str);
}
```

- `copy`关键字修饰的打印结果：

```objective-c
mstr -> testhaha 
self.str -> test
```

- `strong`关键字修饰的打印结果：

```objective-c
mstr -> testhaha 
self.str -> testhaha
```

这个问题的本质在于这句代码，**这句代码的本质呢是在调用 `str` 的 `setter` 方法**，最关键的地方就是要知道 `setter` 方法的内部是怎么写的呢？

```objective-c
self.str = mStr; // 本质是调用 setter 方法
```

```objective-c
- (void)setStr:(NSString *)str {
  if (_str != str) {
    [_str release];
    _str = [str copy]; // 最关键的地方
  }
}
```

- 上面写的这个 `setter` 方法是抛开 `ARC` 环境下的写法，如果传入的新值和之前保存的值不一致，就先将老的值引用计数-1，新值调用 `copy` 方法，赋值给成员变量。
- 传入的 `str` 是什么？传入的 `str` 就是 `mstr`，将一个可变字符串进行 `copy` 后会创建一个新的对象，`_str` 指向了一个新的对象。所以你再去修改曾经的`mStr`的值不会影响`_str`的值。

如果定义字符串属性的时候，使用 `strong` 关键字呢？还是从本质出发，`setter` 方法里的这句代码变了。变成 `retain` 了。所以 `_str` 指向原来的位置，当你修改 `mStr` 的值时候，`_str` 肯定会跟着改变。

```objective-c
_str = [str retain]; // 最关键的地方
```

如果你还不懂，再画个图给你解释：

<img src="/Users/bh/Documents/我的文章/iOS底层原理/把copy聊透/image-20210531163425771.png" alt="image-20210531163425771" style="zoom:50%;" />

<img src="/Users/bh/Documents/我的文章/iOS底层原理/把copy聊透/image-20210531163441028.png" alt="image-20210531163441028" style="zoom:50%;" />

### 3.2 问题2

- 下面代码打印结果是什么？

```objective-c
@interface ViewController ()
@property (nonatomic, copy) NSMutableArray *mArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mArray = [[NSMutableArray alloc] initWithObjects:@"a", @"b", @"c", nil];
    [self.mArray addObject:@"d"];
  	NSLog(@"%@", self.mArray);
}
```

- 没有打印，直接崩溃
- 错误信息：`__NSArrayI` 找不到 `addObject` 方法，

```objective-c
-[__NSArrayI addObject:]: unrecognized selector sent to instance 0x600002704060
```

- 根据问题1的经验，你细品，下面这句代码的本质是什么？
- 就是在调用 `setter`方法，由于是 `copy` 修饰，会创建一个新对象，而新对象是不可变数组，不可变数组调用 `addObject` 方法怎么可能找得到呢？

```objective-c
self.mArray = [[NSMutableArray alloc] initWithObjects:@"a", @"b", @"c", nil];
```

所以最终结果一定是崩溃。

## 四、补充-自定义对象的copy

前面介绍的都是系统自带的类进行 `copy` 的操作，如果是我们自己创建的类呢？

需求：如果类包含了许多属性，我们想通过 `copy` 方法，快速复制一个对象。

```objective-c
@interface LLPerson : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int age;
@property (nonatomic, assign) float height;
@end
  
// 重写description方法，为了更好的观察值
- (NSString *)description方法，为了更好的观察值 {   
    return [NSString stringWithFormat:@"name = %@ age = %d height = %f", self.name, self.age, self.height];
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    LLPerson *p1 = [[LLPerson alloc] init];
    p1.age = 35;
    p1.name = @"LBJ";
    p1.height = 2.03;
    LLPerson *p2 = [p1 copy];
    NSLog(@"\n p1 -> %@ \n p1 -> %@", p1, p2);
    NSLog(@"\n p1 -> %p \n p2 -> %p", p1, p2);

}
```

- 我们调用的 `copy`方法及 `mutableCopy` 方法本质是 `NSObject` 类中的方法
- 创建一个 `Person` 类，我们会发现也可以调用 `copy`方法
- 你会发现运行过程中会程序会崩溃掉，错误如下：`**-[LLPerson copyWithZone:]: unrecognized selector sent to instance 0x6000025339a0**`
- 在LLPerson类中找不到 `copyWithZone` 方法，这也说明了 `copy` 方法的本质是调用了 `copyWithZone` 方法，所以我们需要实现一下 `copyWithZone` 方法，必须要遵守 `NSCopying`协议

```objective-c
@interface LLPerson : NSObject <NSCopying>
@end
  
- (id)copyWithZone:(NSZone *)zone {
    LLPerson *p = [LLPerson allocWithZone:zone];
    p.age = self.age;
    p.name = self.name;
    p.height = self.height;
    return p;
}

```

- 再次运行，看一下打印结果

```objective-c
2020-06-08 12:34:41.269151+0800 05_copy[1703:66976] 
 p1 -> name = LBJ age = 35 height = 2.030000 
 p2 -> name = LBJ age = 35 height = 2.030000
2020-06-08 12:34:41.269252+0800 05_copy[1703:66976] 
 p1 -> 0x600003c23000 
 p2 -> 0x600003c23300
```

- 成功复制出一个 `person` 对象，因为我们在 `copyWithZone` 方法中创建一个新的 `person`对象，显然两个person对象不是同一个对象。

如果我们这样操作：

```objective-c
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

2020-06-08 12:37:34.597352+0800 05_copy[1725:68808] 
 p1 -> name = LBJ age = 35 height = 2.030000 
 p2 -> name = LBJ age = 35 height = 2.030000
2020-06-08 12:37:34.597531+0800 05_copy[1725:68808] 
 p1 -> 0x6000003a29a0 
 p2 -> 0x6000003a29a0
```

- 此时我们复制出来的对象，就指向我们之前创建出来的对象，可以看到他们的地址是完全相同的。
- 所以如果是自己实现 `copy` 操作，到底是深拷贝还是浅拷贝完全由程序员自己来决定。

关于 `mutableCopy` 自定义对象，遵守 `NSMutableCopying` 协议。个人认为可变自定义对象，在工作中意义没有那么大。所以这里就不去实现了，如果自己感兴趣可以自己研究一下。



## 更新于 2021年5月31日