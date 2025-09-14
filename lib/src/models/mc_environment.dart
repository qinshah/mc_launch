/// Minecraft 环境配置
class McEnvironment {
  /// .minecraft 文件夹路径
  static const String minecraftPath = '/Users/qshh/Desktop/Dev/FA/unknown_studio/.minecraft';
  
  /// Java 可执行文件路径
  static const String javaPath = 'java';
  
  /// 版本目录路径
  static String get versionsPath => '$minecraftPath/versions';
  
  /// 库文件目录路径
  static String get librariesPath => '$minecraftPath/libraries';
  
  /// 资源目录路径
  static String get assetsPath => '$minecraftPath/assets';
  
  /// 获取指定版本的目录路径
  static String getVersionPath(String version) {
    return '$versionsPath/$version';
  }
  
  /// 获取指定版本的 jar 文件路径
  static String getVersionJarPath(String version) {
    return '${getVersionPath(version)}/$version.jar';
  }
  
  /// 获取指定版本的 natives 目录路径
  static String getVersionNativesPath(String version) {
    return '${getVersionPath(version)}/natives';
  }
}