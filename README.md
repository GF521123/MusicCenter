# 云盘音乐 (MusicCenter)

基于 Flutter 的云盘音乐播放器。授权接入云盘(阿里云盘首发,百度云盘开发中),选中云盘文件夹后,自动加载其中的音乐与歌词(.lrc),支持边下边播与在线播放双模式。

## 项目信息

| 项 | 值 |
|----|----|
| 项目名 | music_center |
| 显示名称 | 云盘音乐 |
| 包名(applicationId / bundle id) | cn.rivergod.music.center |
| 版本 | 0.1.0+1 |
| 目标平台 | Windows(首发) / Android / iOS(后期) |

## 技术栈

- Flutter(Dart)
- 音频播放:待定(media_kit / audioplayers / just_audio 评估中)

## 目录规划

```
lib/
├── main.dart
├── cloud/        # 云盘抽象层(CloudDrive 接口 + 阿里云实现 + 百度云预留)
├── player/       # 播放核心(双模式:边下边播 / 在线播放)
├── lyrics/       # .lrc 解析与同步
├── model/        # 数据模型(歌曲/专辑/播放列表)
├── data/         # 本地存储(元数据/收藏/缓存索引)
├── ui/           # 界面(主布局/列表/播放页)
└── utils/        # 通用工具
```

## 需求与进度

- 完整需求见 [PRD.md](PRD.md)
- 当前进度:M0 项目初始化 ✅ → M1 阿里云盘接入(未开始)

## 开发环境

- Flutter SDK(`/opt/flutter`)
- Windows 桌面构建需 Visual Studio 2022 + C++ 桌面开发组件(尚未安装)

## 运行

```bash
flutter pub get
flutter run -d windows
```
