import 'dart:io';
import 'package:path/path.dart' as path;
import '../services/version_service.dart';

/// 启动参数构建工具
class LaunchArgsBuilder {
  /// 构建纯净版启动参数
  static List<String> buildVanillaArgs({
    required String versionPath,
    required String minecraftPath,
    required String username,
    int memory = 2048,
  }) {
    final List<String> args = [];
    
    // JVM 基础参数
    args.addAll([
      '-Xmx${memory}M',
      '-Xms${memory}M',
    ]);
    
    // macOS 需要的特殊参数
    if (Platform.isMacOS) {
      args.add('-XstartOnFirstThread');
    }
    
    // 必要的系统参数
    args.addAll([
      '-Djava.library.path=${VersionService.getVersionNativesPath(versionPath)}',
      '-Dminecraft.launcher.brand=mc_launch',
      '-Dminecraft.launcher.version=1.0.0',
      '-cp',
      _buildClasspath(versionPath, minecraftPath),
      'net.minecraft.client.main.Main', // 纯净版固定主类
    ]);
    
    // 游戏启动参数
    args.addAll(_buildGameArgs(
      versionPath: versionPath,
      minecraftPath: minecraftPath,
      username: username,
    ));
    
    return args;
  }
  
  /// 构建类路径
  static String _buildClasspath(String versionPath, String minecraftPath) {
    final List<String> classpathEntries = [];
    
    // 主 jar 文件
    final mainJar = VersionService.getVersionJarPath(versionPath);
    classpathEntries.add(mainJar);
    
    // 添加所有依赖库
    final librariesDir = Directory(path.join(minecraftPath, 'libraries'));
    if (librariesDir.existsSync()) {
      _addJarsFromDirectory(librariesDir, classpathEntries);
    }
    
    return classpathEntries.join(Platform.isWindows ? ';' : ':');
  }
  
  /// 递归添加目录中的 jar 文件
  static void _addJarsFromDirectory(Directory dir, List<String> classpathEntries) {
    try {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.jar')) {
          classpathEntries.add(entity.path);
        }
      }
    } catch (e) {
      // 忽略扫描错误
    }
  }
  
  /// 构建游戏参数
  static List<String> _buildGameArgs({
    required String versionPath,
    required String minecraftPath,
    required String username,
  }) {
    final versionName = VersionService.getVersionNameFromPath(versionPath);
    
    return [
      '--username', username,
      '--version', versionName,
      '--gameDir', minecraftPath,
      '--assetsDir', path.join(minecraftPath, 'assets'),
      '--assetIndex', '26', // 1.21.8 使用的资产索引
      '--userType', 'offline',
      '--accessToken', 'offline_token',
      '--versionType', 'release',
      '--uuid', '00000000-0000-0000-0000-000000000000',
    ];
  }
}