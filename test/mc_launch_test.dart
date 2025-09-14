import 'dart:io';
import 'package:test/test.dart';
import 'package:mc_launch/mc_launch.dart';

void main() {
  group('Minecraft Launcher 启动测试', () {
    // 测试用的 .minecraft 路径
    const testMinecraftPath = '/Users/qshh/Desktop/Dev/FA/unknown_studio/.minecraft';
    
    test('环境验证测试', () async {
      final result = await MinecraftLauncher.validateEnvironment(testMinecraftPath);
      
      expect(result.javaAvailable, isTrue, reason: 'Java 应该可用');
      expect(result.minecraftDirExists, isTrue, reason: '.minecraft 目录应该存在');
      expect(result.isValid, isTrue, reason: '整体环境应该有效');
    });
    
    test('版本检测测试', () {
      final versions = MinecraftLauncher.detectVersions(testMinecraftPath);
      
      expect(versions, isNotEmpty, reason: '应该检测到至少一个版本');
      
      // 验证每个版本路径都是有效的
      for (final versionPath in versions) {
        expect(Directory(versionPath).existsSync(), isTrue, 
            reason: '版本路径应该存在: $versionPath');
        
        // 检查是否有必要的文件
        final versionName = versionPath.split('/').last;
        final jarFile = File('$versionPath/$versionName.jar');
        final jsonFile = File('$versionPath/$versionName.json');
        
        expect(jarFile.existsSync(), isTrue, 
            reason: '版本 jar 文件应该存在: ${jarFile.path}');
        expect(jsonFile.existsSync(), isTrue, 
            reason: '版本 json 文件应该存在: ${jsonFile.path}');
      }
      
      print('检测到的版本:');
      for (final version in versions) {
        print('  - ${version.split('/').last} (${version})');
      }
    });
    
    test('实际启动测试 - 快速检查', () async {
      final versions = MinecraftLauncher.detectVersions(testMinecraftPath);
      
      if (versions.isEmpty) {
        fail('没有可用的版本进行测试');
      }
      
      final testVersionPath = versions.first;
      final testUsername = 'TestPlayer';
      
      print('正在测试启动版本: ${testVersionPath.split('/').last}');
      print('用户名: $testUsername');
      
      try {
        final process = await MinecraftLauncher.launchVanilla(
          versionPath: testVersionPath,
          username: testUsername,
          memory: 1024, // 使用较小内存进行测试
        );
        
        expect(process.pid, greaterThan(0), reason: '进程 ID 应该大于 0');
        
        print('✅ 启动成功，进程 ID: ${process.pid}');
        
        // 等待 3 秒以检查进程是否稳定运行
        await Future.delayed(Duration(seconds: 3));
        
        // 检查进程是否还在运行
        final isRunning = await _isProcessRunning(process.pid);
        expect(isRunning, isTrue, reason: '进程应该仍在运行');
        
        print('✅ 进程运行稳定');
        
        // 终止测试进程
        process.kill();
        
        print('✅ 启动测试完成');
        
      } catch (e) {
        fail('启动失败: $e');
      }
    }, timeout: Timeout(Duration(minutes: 2)));
    
    test('错误处理测试', () async {
      // 测试无效路径
      expect(
        () => MinecraftLauncher.launchVanilla(
          versionPath: '/invalid/path',
          username: 'TestUser',
        ),
        throwsA(isA<LaunchException>()),
      );
      
      // 测试空版本列表
      final emptyVersions = MinecraftLauncher.detectVersions('/invalid/minecraft/path');
      expect(emptyVersions, isEmpty);
    });
  });
}

/// 检查进程是否还在运行
Future<bool> _isProcessRunning(int pid) async {
  try {
    if (Platform.isMacOS || Platform.isLinux) {
      final result = await Process.run('ps', ['-p', pid.toString()]);
      return result.exitCode == 0;
    } else if (Platform.isWindows) {
      final result = await Process.run('tasklist', ['/FI', 'PID eq $pid']);
      return result.exitCode == 0 && result.stdout.toString().contains(pid.toString());
    }
    return false;
  } catch (e) {
    return false;
  }
}