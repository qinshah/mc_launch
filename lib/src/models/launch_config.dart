/// Minecraft 启动配置模型
class LaunchConfig {
  /// MC 版本
  final String version;
  
  /// 玩家用户名
  final String username;
  
  /// 分配内存（MB）
  final int memory;
  
  /// 额外的 JVM 参数
  final List<String> additionalArgs;
  
  /// 游戏目录路径
  final String? gameDir;
  
  const LaunchConfig({
    required this.version,
    required this.username,
    this.memory = 2048,
    this.additionalArgs = const [],
    this.gameDir,
  });
  
  /// 复制并修改配置
  LaunchConfig copyWith({
    String? version,
    String? username,
    int? memory,
    List<String>? additionalArgs,
    String? gameDir,
  }) {
    return LaunchConfig(
      version: version ?? this.version,
      username: username ?? this.username,
      memory: memory ?? this.memory,
      additionalArgs: additionalArgs ?? this.additionalArgs,
      gameDir: gameDir ?? this.gameDir,
    );
  }
  
  @override
  String toString() {
    return 'LaunchConfig(version: $version, username: $username, memory: ${memory}MB)';
  }
}