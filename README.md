<div align="center">
  <h1 align="center">
    <img src="lib/assets/startup.png" width="200">
    <br/>
    Daisy Comic

  <a href="https://trendshift.io/repositories/10633" target="_blank"><img src="https://trendshift.io/api/badge/repositories/10633" alt="Trendshift" style="width: 200px; height: 46px;" width="250" height="46"/></a>
    <br/>

[![license](https://img.shields.io/github/license/niuhuan/daisy)](https://raw.githubusercontent.com/niuhuan/daisy/master/LICENSE)
[![releases](https://img.shields.io/github/v/release/niuhuan/daisy)](https://github.com/niuhuan/daisy/releases)
[![downloads](https://img.shields.io/github/downloads/niuhuan/daisy/total)](https://github.com/niuhuan/daisy/releases)
  </h1>
</div>


<br/>


一个简洁大方的漫画与轻小说客户端, 同时支持支持 Android / iOS / MacOS / Windows / Linux.

如果您觉得此软件对您有帮助，可以star进行支持。同时欢迎您issue，一起让软件变得更好。

仓库地址 https://github.com/niuhuan/daisy

## 软件截图

![](images/st01.png)
![](images/st02.png)

![](images/st03.jpg)
![](images/st04.jpg)


## 技术架构

客户端使用前后端分离架构, flutter作为渲染框架. rust作为底层调度网络和文件系统. Flutter与rust均为跨平台编程语言, 以此支持 android/iOS/windows/macOS 等不同操作系统.

![](https://raw.githubusercontent.com/fzyzcjy/flutter_rust_bridge/master/book/logo.png)

### 如何构建

1. 安装flutter, rust-lang
2. 安装相应平台SDK <br />
  1). cmake, ninja, pkg-config等开发工具 （windows/linux）<br />
  2). 安装 xcode（macOS/iOS/） <br />
  3). android studio, android SDK 等开发工具 (android) <br />
3. 安装`flutter_rust_bridge` 运行 `cargo install flutter_rust_bridge` <br />
4. `flutter run`

### 如何开发调试

阅读flutter_rust_bridge的文档, 了解如何在flutter中调用rust代码.

### 责任声明

- 仓库中的源码您可以按照 [LICENSE](LICENSE) 使用。
- 此APP含有"吸烟/饮酒/斗殴/言情/两性"等内容或间接性描述, 因此理论限制级别为"R12+PG14"，即在12岁以上才能使用, 14岁以下的用户在监护人陪同下使用。
- 作者不作任何软件分发，您应当在使用或传播过程中遵守当地法律法规，因传播载造成的法律问题或纠纷，不承担任何责任，需行为人自行承担。


