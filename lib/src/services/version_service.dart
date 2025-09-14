import 'dart:io';
import '../models/mc_environment.dart';

/// Minecraft 版本管理服务
class VersionService {
  /// 检查指定版本是否已安装
  static bool isVersionInstalled(String version) {
    final versionDir = Directory(McEnvironment.getVersionPath(version));
    final jarFile = File(McEnvironment.getVersionJarPath(version));
    
    return versionDir.existsSync() && jarFile.existsSync();
  }
  
  /// 获取所有已安装的版本列表
  static List<String> getInstalledVersions() {
    final versionsDir = Directory(McEnvironment.versionsPath);
    
    if (!versionsDir.existsSync()) {
      return [];
    }
    
    return versionsDir
        .listSync()
        .whereType<Directory>()
        .map((dir) => dir.path.split('/').last)
        .where((version) => isVersionInstalled(version))
        .toList();
  }
  
  /// 获取第一个可用的版本（用于快速启动）
  static String? getFirstAvailableVersion() {
    final versions = getInstalledVersions();
    return versions.isNotEmpty ? versions.first : null;
  }
}