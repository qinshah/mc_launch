import 'dart:io';
import 'package:test/test.dart';
import 'package:mc_launch/mc_launch.dart';

void main() {
  group('Minecraft Launcher 启动测试', () {
    // 测试用的多个 .minecraft 路径，TODO：请自行使用自己的路径
    final testMinecraftPaths = [
      '/Users/qshh/Desktop/FML/.minecraft',
      '/Users/qshh/Desktop/Dev/FA/unknown_studio/.minecraft', 
      '/Applications/.minecraft'
    ];
    
    test('环境验证测试 - 多路径', () async {
      print('\n=== 环境验证测试 ===');
      
      for (int i = 0; i < testMinecraftPaths.length; i++) {
        final path = testMinecraftPaths[i];
        print('\n测试路径 ${i + 1}: $path');
        
        final result = await MinecraftLauncher.validateEnvironment(path);
        
        print('  Java 可用: ${result.javaAvailable}');
        print('  目录存在: ${result.minecraftDirExists}');
        print('  整体有效: ${result.isValid}');
        
        // Java 应该在所有环境中可用
        expect(result.javaAvailable, isTrue, reason: 'Java 应该可用');
        
        if (result.minecraftDirExists) {
          print('  ✅ 路径有效，可以进行后续测试');
        } else {
          print('  ⚠️ 路径不存在，跳过此路径的后续测试');
        }
      }
    });
    
    test('版本检测测试 - 多路径', () {
      print('\n=== 版本检测测试 ===');
      
      for (int i = 0; i < testMinecraftPaths.length; i++) {
        final path = testMinecraftPaths[i];
        print('\n测试路径 ${i + 1}: $path');
        
        if (!Directory(path).existsSync()) {
          print('  ⚠️ 路径不存在，跳过版本检测');
          continue;
        }
        
        // 首先检测纯净版
        print('  🔍 检测纯净版...');
        final vanillaVersions = MinecraftLauncher.detectVersions(path, includeModded: false, verbose: true);
        
        print('  检测到 ${vanillaVersions.length} 个纯净版:');
        
        if (vanillaVersions.isEmpty) {
          print('  📂 没有找到纯净版');
        } else {
          // 验证每个版本路径都是有效的
          for (final versionPath in vanillaVersions) {
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
            
            print('    ✅ $versionName (纯净版)');
          }
        }
        
        // 然后检测所有版本（包括模组）
        print('  🔍 检测所有版本（包括模组）...');
        final allVersions = MinecraftLauncher.detectVersions(path, includeModded: true, verbose: true);
        
        print('  检测到 ${allVersions.length} 个版本（含模组）:');
        
        if (allVersions.isEmpty) {
          print('  📂 没有找到任何版本');
        } else {
          for (final versionPath in allVersions) {
            final versionName = versionPath.split('/').last;
            final isVanilla = vanillaVersions.contains(versionPath);
            final versionType = isVanilla ? '纯净版' : '模组版';
            print('    ✅ $versionName ($versionType)');
          }
        }
      }
    });
    
    test('实际启动测试 - 多路径快速检查', () async {
      print('\n=== 实际启动测试 ===');
      
      bool anyLaunchSuccessful = false;
      
      for (int i = 0; i < testMinecraftPaths.length; i++) {
        final path = testMinecraftPaths[i];
        print('\n测试路径 ${i + 1}: $path');
        
        if (!Directory(path).existsSync()) {
          print('  ⚠️ 路径不存在，跳过启动测试');
          continue;
        }
        
        final versions = MinecraftLauncher.detectVersions(path, includeModded: true, verbose: false);
        
        if (versions.isEmpty) {
          print('  📂 没有可用版本，跳过启动测试');
          continue;
        }
        
        final testVersionPath = versions.first;
        final testUsername = 'TestPlayer';
        final versionName = testVersionPath.split('/').last;
        
        print('  🎮 正在测试启动版本: $versionName');
        print('  👤 用户名: $testUsername');
        
        try {
          final process = await MinecraftLauncher.launch(
            versionPath: testVersionPath,
            username: testUsername,
            memory: 1024, // 使用较小内存进行测试
          );
          
          expect(process.pid, greaterThan(0), reason: '进程 ID 应该大于 0');
          
          print('  ✅ 启动成功，进程 ID: ${process.pid}');
          
          // 等待 3 秒以检查进程是否稳定运行
          await Future.delayed(Duration(seconds: 3));
          
          // 检查进程是否还在运行
          final isRunning = await _isProcessRunning(process.pid);
          expect(isRunning, isTrue, reason: '进程仍在运行');
          
          print('  ✅ 进程运行稳定');
          
          // 终止测试进程
          process.kill();
          print('  终止测试进程');
          
          print('  ✅ 启动测试完成');
          anyLaunchSuccessful = true;
          
          // 只测试第一个成功的路径
          break;
          
        } catch (e) {
          print('  ❌ 启动失败: $e');
        }
      }
      
      expect(anyLaunchSuccessful, isTrue, reason: '至少应该有一个路径可以成功启动游戏');
    }, timeout: Timeout(Duration(minutes: 2)));
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