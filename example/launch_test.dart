import 'dart:io';
import 'package:mc_launch/mc_launch.dart';

/// 纯净版 Minecraft 启动器测试
void main() async {
  print('=== 纯净版 Minecraft 启动器测试 ===');
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
  
  // 2. 检查所有版本
  print('正在检查已安装的版本...');
  final allVersions = MinecraftLauncher.getInstalledVersions();
  print('所有已安装版本: $allVersions');
  
  if (allVersions.isEmpty) {
    print('❌ 未找到任何 Minecraft 版本');
    return;
  }
  
  // 3. 尝试启动第一个版本
  final version = allVersions.first;
  print('');
  print('=== 纯净版启动测试 ===');
  print('版本: $version');
  print('用户名: VanillaPlayer');
  print('');
  
  try {
    print('正在启动纯净版 Minecraft，请稍候...');
    
    // 使用快速启动
    final process = await MinecraftLauncher.quickLaunch('VanillaPlayer');
    print('✅ Minecraft 启动成功，进程 ID: ${process.pid}');
    print('游戏正在启动中，请查看 Minecraft 窗口...');
    print('');
    
    // 监听进程输出前几秒钟
    print('监听启动日志（前15秒）...');
    var outputCount = 0;
    
    process.stdout.listen((data) {
      final output = String.fromCharCodes(data).trim();
      if (output.isNotEmpty && outputCount < 10) {
        print('[MC输出] $output');
        outputCount++;
      }
    });
    
    process.stderr.listen((data) {
      final output = String.fromCharCodes(data).trim();
      if (output.isNotEmpty && outputCount < 10) {
        print('[MC错误] $output');
        outputCount++;
      }
    });
    
    // 等待15秒或进程结束
    print('');
    print('启动器将监听15秒，然后结束监听...');
    print('（游戏会继续在后台运行）');
    
    final result = await Future.any([
      Future.delayed(Duration(seconds: 15)).then((_) => 'timeout'),
      process.exitCode.then((code) => 'exited:$code'),
    ]);
    
    if (result == 'timeout') {
      print('✅ Minecraft 正在运行中！');
      print('进程 ID: ${process.pid}');
      print('如需关闭游戏，请直接在游戏窗口中退出。');
    } else {
      final exitCode = result.toString().split(':')[1];
      if (exitCode == '0') {
        print('✅ Minecraft 正常退出');
      } else {
        print('⚠️ Minecraft 进程异常退出，退出码: $exitCode');
      }
    }
    
  } catch (e) {
    print('❌ 启动失败: $e');
    print('');
    print('可能的解决方案:');
    print('1. 检查 Java 是否正确安装');
    print('2. 检查 .minecraft 目录是否存在完整版本');
    print('3. 检查版本 jar 文件是否存在');
    print('4. 检查是否有足够的内存');
    print('5. 检查网络连接（首次启动需要下载资源）');
  }
}