# MiHome-Mac

米家设备的 macOS 桌面控制端。它基于 [mijiaAPI](https://github.com/Do1e/mijia-api) 与 [MiHome-Windows](https://github.com/huanyuejue/MiHome-Windows) 的 GPL-3.0 源码移植而来；扫码登录后可在本地查看和控制米家设备。

> 这是 macOS 移植版的首个本地构建。设备功能会随账号下的设备型号而变化，建议先使用测试设备验证控制操作。

## 功能

- 米家 App 扫码登录；凭据与 `mijiaAPI` CLI 共用。
- 按家庭和房间显示设备，并按设备 spec 自动生成开关、滑块、枚举和动作控件。
- 原生 SwiftUI 窗口、侧边栏、右侧设备检查器和 macOS 状态栏菜单。
- 设备检查器会按设备 spec 自动生成开关、菜单、滑杆和动作按钮。
- 设备与上次已知状态缓存保存于 `~/Library/Application Support/MiHome-Mac/`。

## 本地运行

要求：macOS 14 或以上、Python 3.10 或以上、Command Line Tools。

```bash
cd /Users/tongtong/Desktop/person/MiHome-Mac/NativeApp
./script/build_and_run.sh
```

脚本会构建 SwiftUI app、嵌入米家协议桥并启动 `NativeApp/dist/MiHome.app`。

## 构建 DMG

```bash
cd NativeApp
./script/package_dmg.sh
```

产物为 `dist/MiHome-1.0.0-macOS-native.dmg`。打开镜像后，将 `MiHome.app` 拖至 Applications 即可安装。

## 分发说明

本地生成的 DMG 未使用 Apple Developer ID 签名或公证。首次打开时，macOS 可能提示无法验证开发者；在确认来源可信后，可在“系统设置 → 隐私与安全性”选择仍要打开。若需要无提示对外分发，必须使用 Apple Developer Program 证书签名并提交 Apple 公证服务。

## 项目结构

```text
NativeApp/                原生 SwiftUI/AppKit 应用与构建脚本
app/core/                 设备规格与米家协议适配层
script/native_bridge.py   嵌入式协议桥入口
resources/                macOS 图标等打包资源
```

## 许可证

本项目基于 [GPL-3.0](LICENSE) 或更高版本发布；保留上游作者的版权和许可证声明。使用本软件时请遵守小米服务条款。
