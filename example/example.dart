import 'package:mc_launch/mc_launch.dart';

/// Minecraft 启动器 MVP 使用示例
void main() async {
  print('=== Minecraft 启动器 MVP 版本 ===');
  print('Minecraft 路径: ${McEnvironment.minecraftPath}');
  print('');
  
  // 1. 验证环境
  print('正在验证环境...');
  final validation = await MinecraftLauncher.validateEnvironment();
  print('验证结果: $validation');
  
  if (!validation.isValid) {
    print('❌ 环境验证失败');
    if (!validation.javaAvailable) {
      print('  - Java 不可用，请安装 Java');
    }
    if (!validation.minecraftDirExists) {
      print('  - .minecraft 目录不存在: ${McEnvironment.minecraftPath}');
    }
    return;
  }
  
  print('✅ 环境验证通过');
  print('');
  
  // 2. 检查可用版本
  print('正在检查已安装的版本...');
  final versions = MinecraftLauncher.getInstalledVersions();
  
  if (versions.isEmpty) {
    print('❌ 未找到任何已安装的 Minecraft 版本');
    print('请确保在 ${McEnvironment.versionsPath} 目录下有正确的版本文件');
    return;
  }
  
  print('✅ 找到 ${versions.length} 个已安装的版本:');
  for (final version in versions) {
    print('  - $version');
  }
  print('');
  
  // 3. 启动示例（注释掉实际启动代码，避免意外启动）
  print('启动示例（代码演示）:');
  print('');
  
  // 方式 1: 快速启动
  print('// 快速启动（使用第一个可用版本）');
  print('final process1 = await MinecraftLauncher.quickLaunch(\"Player1\");');
  print('');
  
  // 方式 2: 指定配置启动
  print('// 指定配置启动');
  print('final process2 = await MinecraftLauncher.launch(');
  print('  version: \"${versions.first}\",');
  print('  username: \"Player2\",');
  print('  memory: 4096,');
  print('  additionalArgs: [\"-XX:+UseG1GC\"],');
  print(');');
  print('');
  
  print('要实际启动游戏，请取消注释上面的代码');
  
  /* 实际启动代码示例（取消注释以使用）:
  
  try {
    print('正在启动 Minecraft...');
    final process = await MinecraftLauncher.quickLaunch('TestPlayer');
    print('✅ Minecraft 启动成功，进程 ID: ${process.pid}');
    
    // 监听进程输出（可选）
    process.stdout.listen((data) {
      print('MC输出: ${String.fromCharCodes(data)}');
    });
    
    process.stderr.listen((data) {
      print('MC错误: ${String.fromCharCodes(data)}');
    });
    
  } catch (e) {
    print('❌ 启动失败: $e');
  }
  */
}