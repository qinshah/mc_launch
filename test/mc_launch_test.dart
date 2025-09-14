import 'package:test/test.dart';
import 'package:mc_launch/mc_launch.dart';

void main() {
  group('MinecraftLauncher MVP Tests', () {
    test('应该正确获取已安装版本列表', () {
      final versions = MinecraftLauncher.getInstalledVersions();
      expect(versions, isA<List<String>>());
    });
    
    test('应该正确检查不存在的版本', () {
      final result = MinecraftLauncher.isVersionInstalled('nonexistent_version_12345');
      expect(result, isFalse);
    });
    
    test('环境验证应该返回 ValidationResult', () async {
      final result = await MinecraftLauncher.validateEnvironment();
      expect(result, isA<ValidationResult>());
      expect(result.isValid, isA<bool>());
      expect(result.javaAvailable, isA<bool>());
      expect(result.minecraftDirExists, isA<bool>());
    });
    
    test('LaunchConfig 应该正确初始化', () {
      final config = LaunchConfig(
        version: '1.20.1',
        username: 'TestPlayer',
        memory: 4096,
        additionalArgs: ['-XX:+UseG1GC'],
      );
      
      expect(config.version, equals('1.20.1'));
      expect(config.username, equals('TestPlayer'));
      expect(config.memory, equals(4096));
      expect(config.additionalArgs, contains('-XX:+UseG1GC'));
    });
    
    test('LaunchConfig copyWith 应该正确工作', () {
      final original = LaunchConfig(
        version: '1.20.1',
        username: 'TestPlayer',
      );
      
      final modified = original.copyWith(memory: 4096);
      
      expect(modified.version, equals('1.20.1'));
      expect(modified.username, equals('TestPlayer'));
      expect(modified.memory, equals(4096));
    });
    
    test('McEnvironment 常量应该正确设置', () {
      expect(McEnvironment.minecraftPath, equals('/Users/qshh/Desktop/FML/.minecraft'));
      expect(McEnvironment.javaPath, equals('java'));
      expect(McEnvironment.getVersionJarPath('1.20.1'), 
          equals('/Users/qshh/Desktop/FML/.minecraft/versions/1.20.1/1.20.1.jar'));
    });
  });
}
