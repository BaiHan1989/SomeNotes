## 背景

在 iOS 的开发中，`UITableViewCell` 绝对是使用非常高频的控件。在实际开发中我们经常使用的一种架构，也是苹果官方的架构即 `MVC` 架构。也就是 `Model`，`View`，`Controller`对应的就是分别为 `M`， `V`，`C` 。而 `UITableViewCell` 属于 `View` 的部分。这篇文章主要是想聊一下真实开发中`UITableViewCell`的复用问题，文章的后面也会涉及一点儿关于`Controller`瘦身的一些东西。

真实开发情况下，我们的数据来源通常是网络接口返回的 `json`数据或者是本地持久化（数据库等）获取的列表，我们将这些数据转换成`model`，用数组来承载这些`model`数据，作为`UITableView`的数据源。  `UITableViewCell` 来展示列表中的每一项数据，而且大部分的情况下，我们都会选择自定义`Cell`的方式来加载数据，因为`UITableViewCell`大部分情况下是无法满足设计稿的。

## 加载Cell的几种方式

我们先来聊聊，`Cell` 加载数据的方式：

### 暴露`Cell`的子控件进行数据的加载

```objective-c
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  	someModel = _dataSource[indexPath.row];
    TestCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
		cell.nameLabel = someModel.xxx;
    cell.titleLabel = someModel.xxx;
  	cell.dateLabel = someModel.xxx;
    return cell;
}
```

上面这种做法的优点是：

- `Model` 和 `View` 是解耦的。这符合苹果对 `MVC` 架构的期望。
- `Cell` 是可以进行复用的当另外一个列表，也需要同样的 `Cell` 来展示不同 `Model` 的数据的时候可以复用该`Cell`

上面这种做法也有缺点：

- 如果 `Cell` 比较复杂，可能自定义的 `Cell` 中有5个以上的子控件，那么这个方法中就会有大量的赋值代码，不够简洁。
- `Cell` 的声明文件中暴露了太多的子控件，其实有些时候，`Controller` 没必要知道这么多关于 `Cell` 的细节的。

所以在真实开发中，这种方式适用于简单的 `Cell` 结构的数据展示。

基于 `Cell` 比较复杂的情况，就衍生出了另外一种 `Cell` 加载数据的方式

### 不暴露 `Cell` 的子控件，只暴露 `Model`。

```objective-c
// cell.h
#import <UIKit/UIKit.h>

@class SomeModel;

@interface TestCell : UITableViewCell
@property (nonatomic, strong) SomeModel *model;
@end
  
// cell.m
- (void)setModel:(SomeModel *)model {
 		_model = model;
    self.leftLabel.text = model.xxx;
    self.rightLabel.text = model.xxx;
  	self.titleLabel.text = model.xxx;
  	...
}

// controller.m
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  	someModel = _dataSource[indexPath.row];
    TestCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
		cell.model = someModel;
    return cell;
}
```

- 上面这种加载数据的方式，在 `Cell` 中暴露模型，在实现文件中通过重写 `setter` 方法进行数据的赋值。这样做之后，在 `Controller` 中赋值时候，只需要一行代码即可。

当然上面的这种做法也是优缺点共存的。

优点是：

- `Cell` 的细节没有被发现，子控件很好的保留在了 `Cell` 的实现文件中。
- `Controller` 中对 `Cell` 赋值的代码只有一行。

缺点是：

- `Model` 和 `Cell` 之间是耦合的。也就是 `Model` 和 `View` 是耦合的，不太符合苹果 `MVC` 思想。
- `Cell` 的复用性差，如果遇到相同样式的 `Cell` 不同的业务数据，那么我们可能需要再定义一个属于另外一个 `Model` 的属性，在赋值时候会产生重复代码。

## 解决方案

其实，上面的两种 `Cell` 加载数据的方式在开发中都会使用到， 面对不同的情况，可以选择不同的方式，个人认为没有任何问题。我们需要解决的问题是遇到同一种 `Cell` 加载不同的 `Model` 的时候，`Cell` 复用性不好的问题以及 `Model` 和 `View` 的耦合问题。

解决思路：

我们的解决思路是**面向协议**：定义一个协议，让`Model`遵守该协议并实现协议中方法，在 `Cell` 中通过面向协议获取数据，进行数据的加载。`Cell` 中不再需要定义两个`Model` 属性。

```objective-c
// TestCellConfigProtocol
#import <Foundation/Foundation.h>

@protocol TestCellConfigProtocol <NSObject>
- (NSString *)leftContent;
- (NSString *)rightContent;
@end

// Person.h
#import <Foundation/Foundation.h>
#import "TestCellConfigProtocol.h"

@interface Person : NSObject <TestCellConfigProtocol>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *job;

@end

// Person.m

#import "Person.h"

@implementation Person

- (NSString *)leftContent {
    return self.name;
}

- (NSString *)rightContent {
    return self.job;
}

@end
  
// User.h
#import <Foundation/Foundation.h>
#import "TestCellConfigProtocol.h"

@interface User : NSObject <TestCellConfigProtocol>
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *hobby;
@end

// User.m
  
#import "User.h"

@implementation User

- (NSString *)leftContent {
    return self.nickName;
}

- (NSString *)rightContent {
    return self.hobby;
}

@end

// TestCell.h
#import <UIKit/UIKit.h>
#import "TestCellConfigProtocol.h"

@class TestViewModel;
@interface TestCell : UITableViewCell

@property (nonatomic, strong) id <TestCellConfigProtocol> model;

@end
  
// TestCell.m
  
#import "TestCell.h"

@interface TestCell ()
@property (weak, nonatomic) IBOutlet UILabel *leftLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightLabel;
@end

@implementation TestCell

- (void)setModel:(id<TestCellConfigProtocol>)model {
    _model = model;
    
    self.leftLabel.text = model.leftContent;
    self.rightLabel.text = model.rightContent;
}
@end
  
// ViewController.m

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TestCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.model = _persons[indexPath.row];
    return cell;
}

// TestTableViewController.m
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TestCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.model = _users[indexPath.row];
    return cell;
}
```

- 上面就是我面向协议解决该问题的主要步骤，完成了`Model` 和 `View` 之间的解耦，也隐藏了了 `Cell` 的细节，还提高了 `Cell` 的复用性，下一次再来不同的数据，只需要模型遵守我们定义的协议，实现协议中的方法即可。

从这种面向协议的方式达到解耦，让我想到了一种架构即 `MVVM` ，协议就很好的充当了 `VM` 的角色。`VM` 就可以使`Model` 和 `View` 进行之间解耦，`View` 面向 `VM` ，`Model` 面向 `VM` 以及 `Controller` 面向 `VM`。我们还可以把获取数据甚至更多的操作，封装到 `VM` 中，从而对`Controller` 进行瘦身。

[Demo](https://github.com/BaiHan1989/CellsReusable)