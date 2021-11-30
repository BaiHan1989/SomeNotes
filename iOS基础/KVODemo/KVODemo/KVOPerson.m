//
//  KVOPerson.m
//  KVODemo
//
//  Created by 白晗 on 2021/11/30.
//

#import "KVOPerson.h"

@implementation KVOPerson

- (void)manualKVO {
    
    [self willChangeValueForKey:@"age"];
    _age = 46;
    [self didChangeValueForKey:@"age"];
    
}

/// 可以根据实际的业务来禁用 KVO
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    
    if ([key isEqualToString:@"age"]) {
        return YES;
    }
    
    return NO;
}

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
