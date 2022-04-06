//
//  SRSDWebImageController.m
//  SourceRead
//
//  Created by 白晗 on 2022/3/31.
//

#import "SRSDWebImageController.h"

#import <UIImageView+WebCache.h>

@interface SRSDWebImageController ()

@end

@implementation SRSDWebImageController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"SDWebImage";
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    UIImageView *imgView1 = [[UIImageView alloc] initWithFrame:CGRectMake(20, 60, 100, 100)];
    [imgView1 sd_setImageWithURL:[NSURL URLWithString:@"https://upload.jianshu.io/users/upload_avatars/4121307/f918e831-9743-4a02-a579-c7fbf1982dfe.JPG"]];
    imgView1.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:imgView1];
}

@end
