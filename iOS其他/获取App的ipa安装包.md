## 前言

早期的时候获取一个App的ipa安装包有很多方法，比如说通过iTunes、爱思助手等一些第三方的手机助手。目前来看，这几种方式已经不可行了。如果我们想获取别的公司的App的资源，通过这种方式来学习和提高自己。

明确1个概念：

- ipa包，iOS应用程序打包后的后缀名为ipa，本质就是个压缩包

## 准备工作

- 软件

  - **Apple Configurator 2**：通过使用这个软件下载我们需要的App

  <img src="/Users/bh/Documents/我的文章/iOS开发/获取App的ipa安装包/image-20201010153409836.png" alt="image-20201010153409836" style="zoom:50%;" />

  - **cartool**：用来解压资源文件，也就是Assets.car文件。

  <img src="/Users/bh/Documents/我的文章/iOS开发/获取App的ipa安装包/image-20201010153602393.png" alt="image-20201010153602393" style="zoom:50%;" />

## 实践

- 打开**Apple Configurator 2**软件，将我们的手机连接到电脑，并且输入我们的AppleID。你就会看到如下界面：

<img src="/Users/bh/Documents/我的文章/iOS开发/获取App的ipa安装包/image-20201010153916381.png" alt="image-20201010153916381" style="zoom:50%;" />

> 注意：你想要的应用程序的ipa，你的手机中必须要安装才可以。我们这里以懂车帝为例。

- 我们点击添加，选择App

<img src="/Users/bh/Documents/我的文章/iOS开发/获取App的ipa安装包/image-20201010154126643.png" alt="image-20201010154126643" style="zoom:50%;" />

- 在出现的界面中，搜索懂车帝，选中，添加

<img src="/Users/bh/Documents/我的文章/iOS开发/获取App的ipa安装包/image-20201010154223990.png" alt="image-20201010154223990" style="zoom:50%;" />

- 此时就会为我们下载选中的App

<img src="/Users/bh/Documents/我的文章/iOS开发/获取App的ipa安装包/image-20201010154314458.png" alt="image-20201010154314458" style="zoom:50%;" />

- **重点：**下载完成后，会弹出如下界面，**此时什么都不要操作！**，**此时什么都不要操作！**，**此时什么都不要操作！**弹出这个界面说明App已经下载到我们的磁盘上了，接下来就是要找到它了。

<img src="/Users/bh/Documents/我的文章/iOS开发/获取App的ipa安装包/image-20201010154450067.png" alt="image-20201010154450067" style="zoom:50%;" />

- 下载的路径：`~/Library/Group Containers/K36BKF7T3D.group.com.apple.configurator/Library/Caches/Assets/TemporaryItems/MobileApps`

> 波浪号(~)不要丢！！！，一路点下去，就可以找到，懂车帝xxx.ipa。将ipa复制出来即可。

- 回到Apple Configurator 2应用程序，点击**停止**。

- 找到我们复制出来的懂车帝.ipa，修改它的后缀名为.zip，并进行解压。来到Playload，鼠标右键显式包内容。
- 懂车帝的资源文件在Assets.car中。打开[cartool](https://github.com/chenjie1219/cartool)这个工具，将Assets.car 拖进去即可解压。

此时就尽情的学习里面的内容吧。