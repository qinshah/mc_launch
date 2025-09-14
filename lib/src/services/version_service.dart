import 'dart:io';
import 'package:path/path.dart' as path;

/// Minecraft 版本管理服务
class VersionService {
  
  /// 检测指定 .minecraft 路径下的所有游戏版本
  /// 
  /// 参数:
  /// - [minecraftPath]: .minecraft 文件夹路径
  /// 
  /// 返回: 所有可用版本的完整路径列表
  static List<String> detectVersions(String minecraftPath) {
    final versionsDir = Directory(path.join(minecraftPath, 'versions'));
    
    if (!versionsDir.existsSync()) {
      return [];
    }
    
    final List<String> versionPaths = [];
    
    for (final entity in versionsDir.listSync()) {
      if (entity is Directory) {
        final versionName = path.basename(entity.path);
        final jarFile = File(path.join(entity.path, '$versionName.jar'));
        final jsonFile = File(path.join(entity.path, '$versionName.json'));
        
        // 检查版本是否完整（需要有 jar 和 json 文件）
        if (jarFile.existsSync() && jsonFile.existsSync()) {
          versionPaths.add(entity.path);
        }
      }
    }
    
    return versionPaths;
  }
  
  /// 从版本路径中提取版本名称
  static String getVersionNameFromPath(String versionPath) {
    return path.basename(versionPath);
  }
  
  /// 获取版本的 jar 文件路径
  static String getVersionJarPath(String versionPath) {
    final versionName = getVersionNameFromPath(versionPath);
    return path.join(versionPath, '$versionName.jar');
  }
  
  /// 获取版本的 json 文件路径
  static String getVersionJsonPath(String versionPath) {
    final versionName = getVersionNameFromPath(versionPath);
    return path.join(versionPath, '$versionName.json');
  }
  
  /// 获取版本的 natives 文件夹路径
  static String getVersionNativesPath(String versionPath) {
    return path.join(versionPath, 'natives');
  }
}