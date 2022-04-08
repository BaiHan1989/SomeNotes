## 前言

这篇文章主要记录在我在开发中针对 `UIWindow` 的使用。

## 遇到的问题

通常境况下，我在新建一个新的 `iOS` 项目后，每次都会删除 `main.storyboard` 这个文件。然后自己在 `AppDelegate` 中自己来创建一个 `window` 对象。大致就是下面这个样子的：

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    self.window.backgroundColor = [UIColor blueColor];
    
    self.window.rootViewController = [ViewController new];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}
```

最近在项目中遇到一个场景：

`App` 启动后，此时需要 `App` 进行强制更新。强制更新，就要求强制更新的按钮在最顶层，我发现之前代码是通过 `[UIApplication sharedApplication].delegate.window` 获取到 `window` 对象，并在此之上添加强制更新的视图作为它的子视图。貌似好像没有什么问题，其实不然。因为这个强制更新的视图不一定是在最顶层的。因为 `Modal` 出来的 `Controller` 会把它盖住。不信你就试试，这样一来可以进行别的操作算哪门子的强制更新？

## 解决方案

既然 `KeyWindow` 解决不了这个问题，我的解决方案是通过自定义 `window`，并设置 `window` 的级别，这样他就在最顶层了。而自己创建一个 `window` 对象是有一些小细节的。还是通过代码具体看一下：

### 我打算怎么设计

- 自定义 `YMUpdateView` 继承自 `UIView`，提供一个 `show` 接口
- 重写 `\- (**instancetype**)initWithFrame:(CGRect)frame` 方法，自定义 `UI` 视图，主要就是自定义 `window` 对象。`window` 里面的子视图，可以根据自己的业务和 `UI` 设计稿进行自己定制

### 我的实现

部分代码如下：

```objective-c
#import "YMUpdateView.h"

@interface UpdateView ()

@property (nonatomic, strong) UIWindow *window;

@end

@implementation UpdateView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        
        _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _window.windowLevel = UIWindowLevelStatusBar;
        _window.rootViewController = [[UIViewController alloc] init];
        _window.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        
        
    }
    return self;
}


- (void)show {
    _window.hidden = NO;
}

@end

```

- 核心代码就是  `\- (**instancetype**)initWithFrame:(CGRect)frame` 中自己创建一个 `window` 对象。更好一点可以封装一个方法专门来创建 UI 视图。在 `layoutSubviews` 方法中进行布局。
- 注意一点就是，window 对象**必须是被强引用的**
- `windowLevel` 设置为 `UIWindowLevelStatusBar` 级别，它和状态栏在一个级别，一定是在最顶层的
- 在使用的时候，也要用 `strong` 修饰的属性，进行**强引用**。

```objective-c
@interface ViewController ()
@property (nonatomic, strong) UpdateView *uv;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.uv = [[UpdateView alloc] init];
    [self.uv show];
    
    
    // 模拟出现 modal Controller 盖住的情况
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TestViewController *vc = [[TestViewController alloc] init];

        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:vc animated:YES completion:nil];
    });

} /* viewDidLoad */
```

## 结束语

东西不难，但在工作中还比较实用。这只是一个简单的场景。我们经常在一些 `App` 中见到**悬浮球**的功能，我觉得也可以通过自定义 `window` 对象来实现，需要处理的是手势和边界的计算。

