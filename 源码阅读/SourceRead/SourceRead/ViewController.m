//
//  ViewController.m
//  SourceRead
//
//  Created by 白晗 on 2022/3/31.
//

#import "ViewController.h"
#import "SRSDWebImageController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)SDClick {
    
    SRSDWebImageController *sdVc = [[SRSDWebImageController alloc] init];
    [self.navigationController pushViewController:sdVc animated:YES];
}

@end
