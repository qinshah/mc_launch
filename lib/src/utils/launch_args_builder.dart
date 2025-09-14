import '../models/launch_config.dart';
import '../models/mc_environment.dart';

/// 启动参数构建工具
class LaunchArgsBuilder {
  /// 构建完整的启动参数列表
  static List<String> buildArgs(LaunchConfig config) {
    final List<String> args = [];
    
    // JVM 内存参数
    args.addAll([
      '-Xmx${config.memory}M',
      '-Xms${config.memory}M',
    ]);
    
    // 添加额外的 JVM 参数
    args.addAll(config.additionalArgs);
    
    // Minecraft 相关参数
    args.addAll([
      '-Djava.library.path=${McEnvironment.getVersionNativesPath(config.version)}',
      '-Dminecraft.launcher.brand=mc_launch',
      '-Dminecraft.launcher.version=1.0.0',
      '-cp',
      _buildClasspath(config.version),
      'net.minecraft.client.main.Main',
    ]);
    
    // 游戏启动参数
    args.addAll(_buildGameArgs(config));
    
    return args;
  }
  
  /// 构建类路径（简化版本）
  static String _buildClasspath(String version) {
    // MVP 版本：只返回主 jar 文件
    // 完整版本应该解析版本 JSON 文件获取所有依赖库
    return McEnvironment.getVersionJarPath(version);
  }
  
  /// 构建游戏参数
  static List<String> _buildGameArgs(LaunchConfig config) {
    final gameDir = config.gameDir ?? McEnvironment.minecraftPath;
    
    return [
      '--username', config.username,
      '--version', config.version,
      '--gameDir', gameDir,
      '--assetsDir', McEnvironment.assetsPath,
      '--assetIndex', config.version,
      '--userType', 'offline',
    ];
  }
}