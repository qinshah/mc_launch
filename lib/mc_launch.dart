library mc_launch;

// 导出公共 API
export 'src/models/launch_config.dart';
export 'src/models/mc_environment.dart';
export 'src/services/minecraft_launch_service.dart';
export 'src/services/version_service.dart';
export 'src/utils/environment_validator.dart';

// 便捷导入
import 'src/models/launch_config.dart';
import 'src/services/minecraft_launch_service.dart';
import 'src/services/version_service.dart';
import 'src/utils/environment_validator.dart';
import 'dart:io';

/// Minecraft 启动器 - 主要 API 类
class MinecraftLauncher {
  /// 启动 Minecraft
  static Future<Process> launch({
    required String version,
    required String username,
    int memory = 2048,
    List<String> additionalArgs = const [],
  }) async {
    final config = LaunchConfig(
      version: version,
      username: username,
      memory: memory,
      additionalArgs: additionalArgs,
    );
    
    return MinecraftLaunchService.launch(config);
  }
  
  /// 快速启动（使用第一个可用版本）
  static Future<Process> quickLaunch(String username, {int memory = 2048}) {
    return MinecraftLaunchService.quickLaunch(username, memory: memory);
  }
  
  /// 获取已安装的版本列表
  static List<String> getInstalledVersions() {
    return VersionService.getInstalledVersions();
  }
  
  /// 检查版本是否已安装
  static bool isVersionInstalled(String version) {
    return VersionService.isVersionInstalled(version);
  }
  
  /// 验证环境
  static Future<ValidationResult> validateEnvironment() {
    return EnvironmentValidator.validateEnvironment();
  }
}
