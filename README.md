# mc_launch

一个用于启动 Minecraft 的 Flutter package，提供简洁的 API 来管理和启动 Minecraft 游戏。

## 特性

- 🚀 简单易用的 API
- ⚙️ 可配置的启动参数
- 🔍 自动版本检测
- ✅ 环境验证
- 📁 模块化架构

## 快速开始

### 1. 基本用法

```dart
import 'package:mc_launch/mc_launch.dart';

// 快速启动（使用第一个可用版本）
final process = await MinecraftLauncher.quickLaunch('PlayerName');

// 指定版本启动
final process = await MinecraftLauncher.launch(
  version: '1.20.1',
  username: 'PlayerName',
  memory: 4096,
  additionalArgs: ['-XX:+UseG1GC'],
);
```

### 2. 环境检查

```dart
// 验证环境
final validation = await MinecraftLauncher.validateEnvironment();
if (validation.isValid) {
  print('环境准备就绪');
} else {
  print('环境验证失败: $validation');
}

// 检查已安装的版本
final versions = MinecraftLauncher.getInstalledVersions();
print('已安装版本: $versions');
```

### 3. 高级配置

```dart
// 使用 LaunchConfig 进行详细配置
final config = LaunchConfig(
  version: '1.20.1',
  username: 'PlayerName',
  memory: 8192,
  additionalArgs: [
    '-XX:+UseG1GC',
    '-XX:+UnlockExperimentalVMOptions',
    '-XX:G1NewSizePercent=20',
  ],
);

final process = await MinecraftLaunchService.launch(config);
```

## 配置

当前 .minecraft 路径硬编码为: `/Users/qshh/Desktop/FML/.minecraft`

要修改路径，请编辑 `lib/src/models/mc_environment.dart` 文件中的 `minecraftPath` 常量。

## 环境要求

- Java 运行时环境 (JRE)
- 有效的 .minecraft 目录结构
- 至少一个已安装的 Minecraft 版本

## 目录结构

```
lib/
├── mc_launch.dart          # 主入口文件
└── src/
    ├── models/              # 数据模型
    │   ├── launch_config.dart
    │   └── mc_environment.dart
    ├── services/            # 核心服务
    │   ├── minecraft_launch_service.dart
    │   └── version_service.dart
    └── utils/               # 工具类
        ├── environment_validator.dart
        └── launch_args_builder.dart
```

## API 参考

### MinecraftLauncher

主要的启动器类，提供静态方法：

- `launch()` - 启动 Minecraft
- `quickLaunch()` - 快速启动
- `getInstalledVersions()` - 获取已安装版本
- `isVersionInstalled()` - 检查版本是否安装
- `validateEnvironment()` - 验证环境

### LaunchConfig

启动配置类：

```dart
class LaunchConfig {
  final String version;      // MC 版本
  final String username;     // 玩家用户名
  final int memory;          // 内存大小(MB)
  final List<String> additionalArgs; // 额外 JVM 参数
  final String? gameDir;     // 游戏目录（可选）
}
```

## 示例

查看 `example/example.dart` 文件获取完整的使用示例。

## 许可证

本项目使用 MIT 许可证。
