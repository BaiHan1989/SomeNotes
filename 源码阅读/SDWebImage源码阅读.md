## 前言

`SDWebImage` 是在 iOS 开发中的经常使用的网络图片加载框架。为了更好的使用它，所以源码是可以读读的，下面就是它源码的地址：

[SDWebImage](https://github.com/SDWebImage/SDWebImage)

这是官方给的该框架的介绍：

This library provides an async image downloader with cache support. For convenience, we added categories for UI elements like `UIImageView`, `UIButton`, `MKAnnotationView`.

大概意思就是，该框架可以异步下载图片，还支持缓存，还提供了分类方便我们加载图片。

下面又介绍了该框架的功能：

- 针对 UIImageView，UIButton 和 MKAnnotationView 添加了图片加载及缓存的分类，目的是方便调用
- 异步图片下载器
- 异步的内存+磁盘缓存，对过期时间进行管理
- 等等一堆优势吧，具体可以看框架的介绍

支持多种图片格式。总而言之，该框架及其强大，所以有必要去好好读读它的源码，强大一下自己。

## SDWebImage 架构

[SDWebImage 架构](https://github.com/SDWebImage/SDWebImage/wiki/5.6-Code-Architecture-Analysis) 专门有一篇文章来介绍。我觉得需要学习学习。

[SDWebImage 架构中文版官方推荐的](https://looseyi.github.io/post/sourcecode-ios/source-code-sdweb-1/)

先读架构，然后再去源码里一探究竟吧。
