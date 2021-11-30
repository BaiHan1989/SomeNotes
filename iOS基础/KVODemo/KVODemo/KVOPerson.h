//
//  KVOPerson.h
//  KVODemo
//
//  Created by 白晗 on 2021/11/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KVOPerson : NSObject

@property (nonatomic, assign) int age;

/// 手动触发 KVO
- (void)manualKVO;

@end

NS_ASSUME_NONNULL_END
