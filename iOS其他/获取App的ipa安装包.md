## 前言

早期的时候获取一个App的ipa安装包有很多方法，比如说通过iTunes、爱思助手等一些第三方的手机助手。目前来看，这几种方式已经不可行了。如果我们想获取别的公司的App的资源，通过这种方式来学习和提高自己。

明确1个概念：

- ipa包，iOS应用程序打包后的后缀名为ipa，本质就是个压缩包

## 准备工作

- 软件

  - **Apple Configurator 2**：通过使用这个软件下载我们需要的App

<img width="180" alt="image-20201010153409836" src="https://user-images.githubusercontent.com/17879178/132791017-0c75ec2e-4b35-402f-81fd-38d95cbdc84d.png">

  - **cartool**：用来解压资源文件，也就是Assets.car文件。

<img width="180" alt="image-20201010153602393" src="https://user-images.githubusercontent.com/17879178/132791055-d76caf83-40dc-4035-83d9-8f0b52c86725.png">


## 实践

- 打开**Apple Configurator 2**软件，将我们的手机连接到电脑，并且输入我们的AppleID。你就会看到如下界面：

<img width="1000" alt="image-20201010153916381" src="https://user-images.githubusercontent.com/17879178/132791099-99f182d7-85d0-4a9f-b554-5360cbb7036a.png">

> 注意：你想要的应用程序的ipa，你的手机中必须要安装才可以。我们这里以懂车帝为例。

- 我们点击添加，选择App

<img width="277" alt="image-20201010154126643" src="https://user-images.githubusercontent.com/17879178/132791140-24eeb4bf-f120-46ab-8278-ffa88e1eab53.png">

- 在出现的界面中，搜索懂车帝，选中，添加

<img width="611" alt="image-20201010154223990" src="https://user-images.githubusercontent.com/17879178/132791163-0a428c62-151f-4686-8d4a-96f1939ba68c.png">

- 此时就会为我们下载选中的App

<img width="463" alt="image-20201010154314458" src="https://user-images.githubusercontent.com/17879178/132791193-7d6ef03d-4d50-4dee-9e89-a81685113067.png">

- **重点：**下载完成后，会弹出如下界面，**此时什么都不要操作！**，**此时什么都不要操作！**，**此时什么都不要操作！**弹出这个界面说明App已经下载到我们的磁盘上了，接下来就是要找到它了。

<img width="434" alt="image-20201010154450067" src="https://user-images.githubusercontent.com/17879178/132791209-7a5f10ab-9c6c-4bb9-8354-cf0e3fa3bcb7.png">

- 下载的路径：`~/Library/Group Containers/K36BKF7T3D.group.com.apple.configurator/Library/Caches/Assets/TemporaryItems/MobileApps`

> 波浪号(~)不要丢！！！，一路点下去，就可以找到，懂车帝xxx.ipa。将ipa复制出来即可。

- 回到Apple Configurator 2应用程序，点击**停止**。

- 找到我们复制出来的懂车帝.ipa，修改它的后缀名为.zip，并进行解压。来到Playload，鼠标右键显式包内容。
- 懂车帝的资源文件在Assets.car中。打开[cartool](https://github.com/chenjie1219/cartool)这个工具，将Assets.car 拖进去即可解压。

此时就尽情的学习里面的内容吧。
