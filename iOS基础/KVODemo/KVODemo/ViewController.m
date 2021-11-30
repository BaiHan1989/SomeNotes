//
//  ViewController.m
//  KVODemo
//
//  Created by 白晗 on 2021/11/30.
//

#import "ViewController.h"
#import "KVOPerson.h"
#import <objc/runtime.h>


@interface ViewController ()
@property (nonatomic, strong) KVOPerson *person1;
@property (nonatomic, strong) KVOPerson *person2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.person1 = [[KVOPerson alloc] init];
//    self.person1.age = 18;

    self.person2 = [[KVOPerson alloc] init];
//    self.person2.age = 29;

    // 监听 person2 的 age 属性值的改变
    [self.person2 addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"some person"];

    // 获取 person 对象的类对象
//    NSLog(@"%@", object_getClass(self.person1));
//    NSLog(@"%@", object_getClass(self.person2));
//
//    NSLog(@"%@", [object_getClass(self.person2) superclass]);

    NSLog(@"%@ - %@", object_getClass(self.person2), [self printMethodNameOfClass:object_getClass(self.person2)]);
    NSLog(@"%@ - %@", object_getClass(self.person1), [self printMethodNameOfClass:object_getClass(self.person1)]);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 点击控制器的 view 来改变属性的值
//    self.person1.age = 38;
    self.person2.age = 46;



    // 通过 setter 方法给 age 属性赋值
//    [self.person1 setAge:38];
//    [self.person2 setAge:46];

    // 通过 KVC 的方式给 age 属性赋值
//    [self.person1 setValue:@38 forKey:@"age"];
//    [self.person2 setValue:@46 forKey:@"age"];

//    [self.person2 manualKVO];


    // 打印方法的地址
//    NSLog(@"%p", [self.person1 methodForSelector:@selector(setAge:)]);
//    NSLog(@"%p", [self.person2 methodForSelector:@selector(setAge:)]);
//
//    NSLog(@"");

} /* touchesBegan */

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {

    NSLog(@"keyPath：%@，object：%@，change：%@，context：%@", keyPath, object, change, context);
}

- (void)dealloc {
    // 移除监听
    [self.person2 removeObserver:self forKeyPath:@"status"];
}

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
@end
