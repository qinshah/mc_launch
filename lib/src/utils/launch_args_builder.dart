import 'dart:io';
import '../models/launch_config.dart';
import '../models/mc_environment.dart';

/// 启动参数构建工具
class LaunchArgsBuilder {
  /// 构建纯净版启动参数
  static List<String> buildArgs(LaunchConfig config) {
    final List<String> args = [];
    
    // JVM 基础参数
    args.addAll([
      '-Xmx${config.memory}M',
      '-Xms${config.memory}M',
    ]);
    
    // macOS 需要的特殊参数
    if (Platform.isMacOS) {
      args.add('-XstartOnFirstThread');
    }
    
    // 必要的系统参数
    args.addAll([
      '-Djava.library.path=${McEnvironment.getVersionNativesPath(config.version)}',
      '-Dminecraft.launcher.brand=mc_launch',
      '-Dminecraft.launcher.version=1.0.0',
      '-cp',
      _buildClasspath(config.version),
      'net.minecraft.client.main.Main', // 纯净版固定主类
    ]);
    
    // 游戏启动参数
    args.addAll(_buildGameArgs(config));
    
    return args;
  }
  
  /// 构建类路径
  static String _buildClasspath(String version) {
    final List<String> classpathEntries = [];
    
    // 主 jar 文件
    final mainJar = McEnvironment.getVersionJarPath(version);
    classpathEntries.add(mainJar);
    
    // 添加所有依赖库
    final librariesDir = Directory(McEnvironment.librariesPath);
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
  static List<String> _buildGameArgs(LaunchConfig config) {
    final gameDir = config.gameDir ?? McEnvironment.minecraftPath;
    
    return [
      '--username', config.username,
      '--version', config.version,
      '--gameDir', gameDir,
      '--assetsDir', McEnvironment.assetsPath,
      '--assetIndex', '26', // 1.21.8 使用的资产索引
      '--userType', 'offline',
      '--accessToken', 'offline_token',
      '--versionType', 'release',
      '--uuid', '00000000-0000-0000-0000-000000000000',
    ];
  }
}