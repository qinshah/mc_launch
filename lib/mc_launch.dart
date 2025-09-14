library mc_launch;

// 导出公共 API
export 'src/models/launch_config.dart';
export 'src/services/minecraft_launch_service.dart';
export 'src/utils/environment_validator.dart';

// 便捷导入
import 'src/services/minecraft_launch_service.dart';
import 'src/services/version_service.dart';
import 'src/utils/environment_validator.dart';
import 'dart:io';

/// Minecraft 启动器 - 主要 API 类
class MinecraftLauncher {
  
  /// 1. 检测游戏版本
  /// 
  /// 参数:
  /// - [minecraftPath]: .minecraft 文件夹路径
  /// 
  /// 返回: 所有可用版本的完整路径列表
  static List<String> detectVersions(String minecraftPath) {
    return VersionService.detectVersions(minecraftPath);
  }
  
  /// 2. 启动游戏（纯净版）
  /// 
  /// 参数:
  /// - [versionPath]: 版本的完整路径（从 detectVersions 返回的路径之一）
  /// - [username]: 游戏用户名
  /// - [memory]: 内存大小（MB），默认 2048
  /// 
  /// 返回: 启动的进程
  static Future<Process> launchVanilla({
    required String versionPath,
    required String username,
    int memory = 2048,
  }) async {
    return MinecraftLaunchService.launchVanilla(
      versionPath: versionPath,
      username: username,
      memory: memory,
    );
  }
  
  /// 验证环境（检查 Java 和 .minecraft 目录）
  /// 
  /// 参数:
  /// - [minecraftPath]: .minecraft 文件夹路径
  static Future<ValidationResult> validateEnvironment(String minecraftPath) {
    return EnvironmentValidator.validateEnvironment(minecraftPath);
  }
}