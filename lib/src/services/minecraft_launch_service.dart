import 'dart:io';
import '../models/launch_config.dart';
import '../models/mc_environment.dart';
import '../utils/launch_args_builder.dart';
import '../utils/environment_validator.dart';
import 'version_service.dart';

/// Minecraft 启动器服务 (MVP 版本)
class MinecraftLaunchService {
  /// 启动 Minecraft
  static Future<Process> launch(LaunchConfig config) async {
    // 验证环境
    final validation = await EnvironmentValidator.validateEnvironment();
    if (!validation.isValid) {
      throw LaunchException('环境验证失败: $validation');
    }
    
    // 验证版本
    if (!EnvironmentValidator.validateVersion(config.version)) {
      throw LaunchException('版本 ${config.version} 未安装或文件缺失');
    }
    
    // 构建启动参数
    final args = LaunchArgsBuilder.buildArgs(config);
    
    print('启动命令: ${McEnvironment.javaPath} ${args.join(' ')}');
    
    // 启动进程
    try {
      final process = await Process.start(
        McEnvironment.javaPath,
        args,
        workingDirectory: McEnvironment.minecraftPath,
        mode: ProcessStartMode.normal,
      );
      
      print('Minecraft 启动成功，进程 ID: ${process.pid}');
      return process;
    } catch (e) {
      throw LaunchException('启动失败: $e');
    }
  }
  
  /// 快速启动（使用第一个可用版本）
  static Future<Process> quickLaunch(String username, {int memory = 2048}) async {
    final version = VersionService.getFirstAvailableVersion();
    if (version == null) {
      throw LaunchException('未找到任何已安装的 Minecraft 版本');
    }
    
    final config = LaunchConfig(
      version: version,
      username: username,
      memory: memory,
    );
    
    return launch(config);
  }
}

/// 启动异常
class LaunchException implements Exception {
  final String message;
  
  const LaunchException(this.message);
  
  @override
  String toString() => 'LaunchException: $message';
}