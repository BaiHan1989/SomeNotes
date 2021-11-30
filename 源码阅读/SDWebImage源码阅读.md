## 概述

`SDWebImage` 是在 iOS 开发中的经常使用的网络图片加载框架。为了更好的使用它，所以源码得读一读

[SDWebImage](https://github.com/SDWebImage/SDWebImage)

该框架支持图片的异步下载及缓存。同时，为一些 UI 元素提供了 `Categories` ，比如 `UIImageView`、`UIButton` 、`MKAnnotataionView`。

## 源码分析

在开发中使用常用的分类是 `UIImageView+WebCache` ，从这个分类的常用方法作为入口进行分析和阅读。



