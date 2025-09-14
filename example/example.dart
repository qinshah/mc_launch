import 'dart:io';
import 'package:mc_launch/mc_launch.dart';

/// Minecraft 启动器使用示例
void main() async {
  print('=== Minecraft 启动器使用示例 ===');
  
  // 硬编码的 .minecraft 路径（在实际使用中，这应该由用户提供）
  const minecraftPath = '/Users/qshh/Desktop/Dev/FA/unknown_studio/.minecraft';
  
  print('使用的 .minecraft 路径: $minecraftPath');
  print('');
  
  // 第一步：验证环境
  print('1. 验证环境...');
  final validation = await MinecraftLauncher.validateEnvironment(minecraftPath);
  print('验证结果: $validation');
  
  if (!validation.isValid) {
    print('❌ 环境验证失败，请检查:');
    if (!validation.javaAvailable) {
      print('  - Java 未安装或不在 PATH 中');
    }
    if (!validation.minecraftDirExists) {
      print('  - .minecraft 目录不存在: $minecraftPath');
    }
    return;
  }
  
  print('✅ 环境验证通过');
  print('');
  
  // 第二步：检测游戏版本
  print('2. 检测游戏版本...');
  final versionPaths = MinecraftLauncher.detectVersions(minecraftPath);
  
  if (versionPaths.isEmpty) {
    print('❌ 未找到任何游戏版本');
    print('请确保 $minecraftPath/versions 目录中有有效的游戏版本');
    return;
  }
  
  print('找到 ${versionPaths.length} 个游戏版本:');
  for (int i = 0; i < versionPaths.length; i++) {
    final versionName = versionPaths[i].split('/').last;
    print('  $i. $versionName');
    print('     路径: ${versionPaths[i]}');
  }
  print('');
  
  // 第三步：选择版本（这里简单选择第一个）
  print('3. 选择版本...');
  print('请输入要启动的版本编号 (0-${versionPaths.length - 1})，或直接回车选择第一个:');
  
  final input = stdin.readLineSync()?.trim() ?? '';
  int selectedIndex = 0;
  
  if (input.isNotEmpty) {
    try {
      selectedIndex = int.parse(input);
      if (selectedIndex < 0 || selectedIndex >= versionPaths.length) {
        print('无效的编号，使用第一个版本');
        selectedIndex = 0;
      }
    } catch (e) {
      print('输入无效，使用第一个版本');
      selectedIndex = 0;
    }
  }
  
  final selectedVersionPath = versionPaths[selectedIndex];
  final selectedVersionName = selectedVersionPath.split('/').last;
  
  print('选择的版本: $selectedVersionName');
  print('版本路径: $selectedVersionPath');
  print('');
  
  // 第四步：启动游戏
  print('4. 启动游戏...');
  print('请输入游戏用户名（或直接回车使用 Player）:');
  
  final usernameInput = stdin.readLineSync()?.trim() ?? '';
  final username = usernameInput.isEmpty ? 'Player' : usernameInput;
  
  print('用户名: $username');
  print('正在启动 Minecraft，请稍候...');
  print('');
  
  try {
    final process = await MinecraftLauncher.launchVanilla(
      versionPath: selectedVersionPath,
      username: username,
      memory: 2048,
    );
    
    print('✅ Minecraft 启动成功！');
    print('进程 ID: ${process.pid}');
    print('');
    print('游戏正在启动中，请查看 Minecraft 窗口...');
    print('监听游戏输出（前 10 秒）:');
    
    // 监听进程输出
    var outputCount = 0;
    
    process.stdout.listen((data) {
      final output = String.fromCharCodes(data).trim();
      if (output.isNotEmpty && outputCount < 5) {
        print('[游戏输出] $output');
        outputCount++;
      }
    });
    
    process.stderr.listen((data) {
      final output = String.fromCharCodes(data).trim();
      if (output.isNotEmpty && outputCount < 5) {
        print('[游戏错误] $output');
        outputCount++;
      }
    });
    
    // 等待 10 秒或进程结束
    final result = await Future.any([
      Future.delayed(Duration(seconds: 10)).then((_) => 'timeout'),
      process.exitCode.then((code) => 'exited:$code'),
    ]);
    
    if (result == 'timeout') {
      print('');
      print('✅ Minecraft 正在运行中！');
      print('进程 ID: ${process.pid}');
      print('要关闭游戏，请直接在游戏窗口中退出。');
    } else {
      final exitCode = result.toString().split(':')[1];
      if (exitCode == '0') {
        print('✅ Minecraft 正常退出');
      } else {
        print('⚠️ Minecraft 异常退出，退出码: $exitCode');
      }
    }
    
  } catch (e) {
    print('❌ 启动失败: $e');
    print('');
    print('可能的解决方案:');
    print('1. 检查 Java 是否正确安装');
    print('2. 检查游戏版本文件是否完整');
    print('3. 检查是否有足够的内存');
  }
}
