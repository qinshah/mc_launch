import 'dart:io';
import 'package:path/path.dart' as path;
import '../utils/launch_args_builder.dart';
import 'version_service.dart';

/// Minecraft 启动器服务
class MinecraftLaunchService {

  /// 启动Minecraft
  /// 
  /// 参数:
  /// - [versionPath]: 版本的完整路径
  /// - [username]: 游戏用户名
  /// - [memory]: 内存大小（MB）
  static Future<Process> launch({
    required String versionPath,
    required String username,
    int memory = 2048,
  }) async {
    // 验证版本路径
    if (!Directory(versionPath).existsSync()) {
      throw LaunchException('版本路径不存在: $versionPath');
    }
    
    // 验证版本文件
    final jarPath = VersionService.getVersionJarPath(versionPath);
    final jsonPath = VersionService.getVersionJsonPath(versionPath);
    
    if (!File(jarPath).existsSync()) {
      throw LaunchException('版本 jar 文件不存在: $jarPath');
    }
    
    if (!File(jsonPath).existsSync()) {
      throw LaunchException('版本 json 文件不存在: $jsonPath');
    }
    
    // 获取 .minecraft 根目录
    final minecraftPath = path.dirname(path.dirname(versionPath));
    
    // 验证 Java 环境
    final javaPath = await _findJavaExecutable();
    
    // 构建启动参数
    final args = LaunchArgsBuilder.buildVanillaArgs(
      versionPath: versionPath,
      minecraftPath: minecraftPath,
      username: username,
      memory: memory,
    );
    
    print('启动命令: $javaPath ${args.join(' ')}');
    
    // 启动进程
    try {
      final process = await Process.start(
        javaPath,
        args,
        workingDirectory: minecraftPath,
        mode: ProcessStartMode.normal,
      );
      
      print('Minecraft 启动成功，进程 ID: ${process.pid}');
      return process;
    } catch (e) {
      throw LaunchException('启动失败: $e');
    }
  }

  
  /// 查找 Java 可执行文件
  static Future<String> _findJavaExecutable() async {
    // 尝试常见的 Java 路径
    final javaPaths = [
      'java', // 系统 PATH 中的 java
      '/usr/bin/java',
      '/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java',
    ];
    
    for (final javaPath in javaPaths) {
      try {
        final result = await Process.run(javaPath, ['-version']);
        if (result.exitCode == 0) {
          return javaPath;
        }
      } catch (e) {
        // 继续尝试下一个路径
      }
    }
    
    throw LaunchException('未找到 Java 可执行文件，请确保 Java 已正确安装');
  }
}

/// 启动异常
class LaunchException implements Exception {
  final String message;
  
  const LaunchException(this.message);
  
  @override
  String toString() => 'LaunchException: $message';
}