## 一、KVC

在开发中，我们可以通过使用 `KVC` 的方式来对某个对象的属性进行赋值/取值操作。

经常会用到以下 `API`：

```objective-c
// 设置值
- (void)setValue:(nullable id)value forKey:(NSString *)key;
- (void)setValue:(nullable id)value forKeyPath:(NSString *)keyPath;
// 获取值
- (nullable id)valueForKeyPath:(NSString *)keyPath;
- (nullable id)valueForKey:(NSString *)key;
```

### 1.1 赋值操作

接下来我们就研究一下 `KVC` 的调用原理：

如果我们给某个类定义一个属性，那么编译器会自动生成 `getter` 和 `setter` 方法，如果通过 `KVC` 给该属性进行赋值操作，默认会调用 `setter` 方法进行赋值。但是这不能完全搞清楚 `KVC` 是如何工作的。

我们定义一个 `Person` 类，但是我们并不给 `Person` 定义任何的属性。接下来创建 `person` 对象，通过 `KVC` 的方式给 `person` 的 `age` 属性进行赋值操作。

```objective-c

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        Person *person = [[Person alloc] init];
        
        [person setValue:@(20) forKey:@"age"];
    }
    return 0;
}
```

1. 去 `Person` 类中查找有没有 `- (void)setAge:` 方法，如果有那么就进行赋值操作；如果没有再去查找有没有 `- (void)_setAge:` 方法，如果有就进行赋值的操作。
2. 如果以上两个方法都没找到，那么就会调用 `- (Bool)accessInstanceVariablesDirectly` 方法，该方法是询问是否可以直接访问成员变量，返回 `NO` 就直接抛出异常未定义的 `Key`
3. 如果 `- (Bool)accessInstanceVariablesDirectly` 返回的是 `YES`（如果不实现该方法默认返回的就是 `YES`），那么就直接去成员变量中**按顺序**查找以下成员变量：`_age` 、`_isAge`、`age`、 `isAge`。如果找到4个成员变量中的1位，那么就进行赋值，否则抛出异常未定义的 `Key`

```objective-c
// Person.h
#import <Foundation/Foundation.h>

@interface Person : NSObject {
    @public
    int _age; // 最先查找
    int _isAge; // 老2
    int age; // 老3
    int isAge; // 老小
  
  	// 如果以上4个成员变量都没有，抛异常
}

@end
  
// Person.m 
#import "Person.h"

@implementation Person
  
// 如果有最先调用
- (void)setAge:(int)age {
    NSLog(@"setAge - %d", age);
}

// 如果没有 setAge 方法，调用该方法
- (void)_setAge:(int)age {
    NSLog(@"_setAge - %d", age);
}

// 如果以上两个方法都没有，且该方法返回 YES，就去查找 成员变量
// 如果以上两个方法都没有，且该方法返回 NO，直接抛异常
+ (BOOL)accessInstanceVariablesDirectly {
    return YES;
}

@end
```

### 1.2 取值操作

`KVC` 的取值操作也会按照一定的顺序进行操作的。

1. 在 `Person` 的实现文件中，按照 `-(int)getAge` 、`- (int)age` 、`- (int)isAge` 、`-(int)_age` 顺序进行，看有没有实现这4个方法中的其中1个，如果有那么调用
2. 如果没有实现上面的4个方法，继续查看 `+ (BOOL)accessInstanceVariablesDirectly` 方法的返回值是否为 `YES`
3. 如果 `+ (BOOL)accessInstanceVariablesDirectly` 方法返回值为 `NO`，直接抛出异常，如果为 `YES`，那么就去按顺序查找 `Person` 的成员变量是不是 `_age` 、`_isAge`、`age`、`isAge` 中的一个，如果有4个成员变量中的1个，那么就取他们的值。

```objective-c
// Person.m
#import "Person.h"

@implementation Person
- (int)getAge {
    return 11;
}

- (int)age {
    return 12;
}

- (int)isAge {
    return 13;
}

- (int)_age {
    return 14;
}

+ (BOOL)accessInstanceVariablesDirectly {
    return YES;
}

@end
  
// main.m
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        Person *person = [[Person alloc] init];
        person->age = 11;
        person->_age = 12;
        person->isAge = 13;
        person->_isAge = 14;
        
        NSLog(@"%@", [person valueForKey:@"age"]);
    }
    return 0;
}
```

## 二、KVO

`KVO` 全称是 `KeyValueObserving` ，中文名称时键值观察，是苹果提供的一套事件通知机制。可以用一个对象来监听另外一个对象的属性的改变，当该对象的属性的值发生改变的时候，可以对属性变化进行监听。

`KVO` 和 `NSNotificationCenter` 都是 `iOS` 中观察者模式的一种实现。他们的区别在于相对于被观察者和观察者之间的关系，`KVO` 是一对一的，而 `NSNotificationCenter` 是可以一对多的。

`KVO` 的一些实现细节可以查看这个文档：[KVO的实现细节](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOImplementation.html)

`KVO` 的实现就是利用了在运行时动态的修改 `isa` 的指向的技术。

### 2.1 KVO 的基本使用

`KVO` 的使用分为3个步骤

1. 通过 `addObserver:forKeyPath:options:context:` 方法注册观察者，观察者可以监听 `keyPath` 属性变化的回调
2. 在观察者中实现 `observeValueForKeyPath:ofObject:change:context:` 方法，当被监听的属性发生改变后，会回调该方法
3. 当观察者不需要监听时，可以调用 `removeObserver:forKeyPath:` 方法将观察者进行移除，在观察者对象销毁之前调用 `removeObserver:forKeyPath:` 方法，否则会程序会崩溃

eg:

- 定义一个 `KVOPerson` 类，`KVOPerson` 包含一个 `age` 属性
- 创建两个 `person` 对象，其中 `person1` 不做任何监听，`person2` 添加 `KVO` 监听，监听 `age` 属性的改变
- 点击控制器的 `view` 来修改 `person` 的 `age` 属性的值

```objective-c
#import "ViewController.h"
#import "KVOPerson.h"

@interface ViewController ()
@property (nonatomic, strong) KVOPerson *person1;
@property (nonatomic, strong) KVOPerson *person2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.person1 = [[KVOPerson alloc] init];
    self.person1.age = 18;
    
    self.person2 = [[KVOPerson alloc] init];
    self.person2.age = 29;
    
    // 监听 person2 的 age 属性值的改变
    [self.person2 addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"some person"];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 点击控制器的 view 来改变属性的值
    self.person1.age = 38;
    self.person2.age = 46;
  
  	// 通过 setter 方法给 age 属性赋值
    [self.person1 setAge:38];
    [self.person2 setAge:46];
  
    // 通过 KVC 的方式给 age 属性赋值
    [self.person1 setValue:@38 forKey:@"age"];
    [self.person2 setValue:@46 forKey:@"age"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    NSLog(@"keyPath：%@，object：%@，change：%@，context：%@", keyPath, object, change, context);
}

- (void)dealloc {
    // 移除监听
    [self.person2 removeObserver:self forKeyPath:@"status"];
}
@end
  
// 打印结果：
// 点击控制器的 view，打印新值和旧值，以及传递过来的 context 的值，属性是 age
2021-11-30 14:05:58.597294+0800 KVODemo[4888:1605565] keyPath：age，object：<KVOPerson: 0x6000011cca10>，change：{
    kind = 1;
    new = 46;
    old = 29;
}，context：some person

```

- 使用点语法、`setter` 方法和`KVC` 的方式均可以触发 `KVO`
- 直接修改成员变量的值是不会触发 `KVO` 的
- 如果想要手动触发 `KVO`，需要调用两个方法，`willChangeValueForKey:` 和 `didChangeValueForKey:` ，只调用其中任意一个都不会触发 `KVO`，两个方法的调用顺序也不能修改。

```objective-c
- (void)manualKVO {
    [self willChangeValueForKey:@"age"];
    _age = 46;
    [self didChangeValueForKey:@"age"];
    
}
```

- 禁用 `KVO`，**注意手动触发 `KVO` 不会被禁用方法影响**

```objective-c
/// 可以根据实际的业务来禁用 KVO
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    
    if ([key isEqualToString:@"age"]) {
        return YES;
    }
    
    return NO;
}
```



以上就是 `KVO` 的基本使用。接下来我们就研究一下 `KVO` 的本质

### 2.2 KVO 的本质（实现原理）

上面的代码，我们改变 `age` 的值，本质是调用 `setter` 方法进行 `age` 的值修改，我们可能会认为程序在运行时 `setter` 方法做了手脚来实现监听，其实不是的，问题出在 `person` 对象上。

我们可以通过在为 `person1` 添加观察者之后来打印一下 `person1` 和 `person2` 的 `isa` 指向来获取他们的类对象

```objective-c
// 获取 person 对象的类对象
NSLog(@"%@", object_getClass(self.person1));
NSLog(@"%@", object_getClass(self.person2));

// 打印结果：
KVOPerson
NSKVONotifying_KVOPerson
```

- `person2` 对象的 `isa` 指向发生了变化，指向了 `NSKVONotifying_KVOPerson`，`NSKVONotifying_KVOPerson`就是 `person2` 的类对象
- `person1` 没有进行 `KVO` 监听，所以 `person1` 的 `isa` 指向没有改变，还是 `KVOPerson`

`NSKVONotifying_Person` 是在程序运行时为我们动态添加的类，而该类是继承 `Person` 的，即它的 `superclass` 指针指向了 `Person`，调用下面的代码可以验证该结论。

```objective-c
NSLog(@"%@", [object_getClass(self.person2) superclass]);
// 打印结果：KVOPerson
```

`KVO` 又是怎么对 `person2` 的 `age` 属性进行监听的呢？

- `person2` 通过  `isa` 指针找到它的类对象即 `NSKVONotifying_KVOPerson`，在 `NSKVONotifying_KVOPerson`内部也存储着一个 `setAge:` 方法，该方法内部调用了 `_NSSetIntValueAndNotify` 函数
- `_NSSetIntValueAndNotify` 函数内部首先是调用了 `- (void)willChangeValueForKey:` 方法，然后通过 `[super setAge:]` 方法去调用父类真正的赋值操作，最后调用 `- (void)didChangeValueForKey:` 方法
- 在 `- (void)didChangeValueForKey:` 内部调用`- (void)observeValueForKeyPath:ofObject:change:context: `方法最终完成属性值的监听操作。

怎么证明是调用了 `_NSSetIntValueAndNotify` 方法呢？

我们可以利用 `lldb` 命令来查看一下：

```objective-c
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.person1.age = 38;
    self.person2.age = 46;
  	// 打印方法的地址
    NSLog(@"%p", [self.person1 methodForSelector:@selector(setAge:)]);
    NSLog(@"%p", [self.person2 methodForSelector:@selector(setAge:)]);
}

// 打印结果：
0x10ec9ec60
0x10fcb7963

lldb:
p (IMP)0x10ec9ec60 => (IMP) $0 = 0x000000010ec9ec60 (KVODemo`-[KVOPerson setAge:] at KVOPerson.h:14)
p (IMP)0x10fcb7963 => (IMP) $1 = 0x000000010fcb7963 (Foundation`_NSSetIntValueAndNotify)
```

我们可以通过一些打印来观察一下具体是什么时候进行监听的：

- 重写 `KVOPerson` 对象的 `setter` 方法、`willChangeValueForKey:` 方法以及 `didChangeValueForKey:` 方法

```objective-c
@implementation KVOPerson

- (void)setAge:(int)age {
    _age = age;
    
    NSLog(@"setAge:");
}

- (void)willChangeValueForKey:(NSString *)key {
    [super willChangeValueForKey:key];
    
    NSLog(@"willChangeValueForKey:");
}

- (void)didChangeValueForKey:(NSString *)key {
    NSLog(@"didChangeValueForKey: => begin");
    [super didChangeValueForKey:key];
    NSLog(@"didChangeValueForKey: => end");
}

@end

// 打印结果：
2021-11-30 16:21:25.967637+0800 KVODemo[14349:1727809] willChangeValueForKey:
2021-11-30 16:21:25.967851+0800 KVODemo[14349:1727809] setAge:
2021-11-30 16:21:25.967993+0800 KVODemo[14349:1727809] didChangeValueForKey: => begin
2021-11-30 16:21:25.968538+0800 KVODemo[14349:1727809] keyPath：age，object：<KVOPerson: 0x600001024740>，change：{
    kind = 1;
    new = 46;
    old = 0;
}，context：some person
2021-11-30 16:21:25.968802+0800 KVODemo[14349:1727809] didChangeValueForKey: => end
```

- 通过打印结果可以观察打印顺序，先调用 `willChangeValueForKey:` 再调用 `setAge:` 方法去修改值，最后再 `didChangeForKey:` 方法中来监听属性的改变

前面已经得出结论，`person2` 的类对象已经变成了 `NSKVONotifying_KVOPerson` 类，而且 `NSKVONotifying_KVOPerson` 中还重写了 `setAge` 方法，其实内部不仅仅有 `setAge` 方法，还有三个方法，分别为 `class`，`dealloc` 方法和 `_isKVOA` 方法。

- 重写 `class` 方法的目的是当我们调用 `[person2 class]` 方法时，返回的是 `Person` 类，从而防止 `NSKVONotifying_Person` 类暴露出来，因为苹果本身是不希望我们去过多关注 `NSKVONotifying_Person` 类的。
- `dealloc` 方法在 `NSKVONotifying_KVOPerson` 类使用完毕后进行一些收尾的工作，因为是不开源的所以这里也只是一个猜测
- `_isKVOA` 方法目的是返回布尔类型告诉系统是否和 `KVO` 有关。

我们可以利用 runtime 来查看一个类对象中的方法名称：

```objective-c
/// 传入类/元类对象，返回其中的方法名称
- (NSString *)printMethodNameOfClass:(Class)cls {
    
    unsigned int count;
    // 获取类中的所有方法
    Method *methodList = class_copyMethodList(cls, &count);
    
    NSMutableString *methodNames = [NSMutableString string];
    
    for (int i = 0; i < count; i++) {
        // 获取方法
        Method method = methodList[i];
        // 获取方法名
        NSString *methodName = NSStringFromSelector(method_getName(method));
        
        [methodNames appendFormat:@"%@ ", methodName];
    }
    
    return methodNames;
}

NSLog(@"%@ - %@", object_getClass(self.person2), [self printMethodNameOfClass:object_getClass(self.person2)]);
NSLog(@"%@ - %@", object_getClass(self.person1), [self printMethodNameOfClass:object_getClass(self.person1)]);

// 打印结果：
2021-11-30 16:27:12.413192+0800 KVODemo[14748:1734276] NSKVONotifying_KVOPerson - setAge: class dealloc _isKVOA
2021-11-30 16:27:12.413364+0800 KVODemo[14748:1734276] KVOPerson - manualKVO willChangeValueForKey: didChangeValueForKey: age setAge:
```

`KVO` 的实现原理利用 `isa-swizzling` 技术实现的，在运行时对 `isa` 的指向进行了修改。

## 修改时间：2021年11月30日