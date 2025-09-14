import 'dart:io';
import '../models/mc_environment.dart';

/// 环境验证工具
class EnvironmentValidator {
  /// 验证 Java 环境
  static Future<bool> validateJava() async {
    try {
      final result = await Process.run('which', ['java']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// 验证 .minecraft 目录
  static bool validateMinecraftDir() {
    final minecraftDir = Directory(McEnvironment.minecraftPath);
    return minecraftDir.existsSync();
  }
  
  /// 验证指定版本
  static bool validateVersion(String version) {
    final versionDir = Directory(McEnvironment.getVersionPath(version));
    final jarFile = File(McEnvironment.getVersionJarPath(version));
    
    return versionDir.existsSync() && jarFile.existsSync();
  }
  
  /// 完整环境验证
  static Future<ValidationResult> validateEnvironment() async {
    final javaValid = await validateJava();
    final minecraftDirValid = validateMinecraftDir();
    
    return ValidationResult(
      javaAvailable: javaValid,
      minecraftDirExists: minecraftDirValid,
      isValid: javaValid && minecraftDirValid,
    );
  }
}

/// 验证结果
class ValidationResult {
  final bool javaAvailable;
  final bool minecraftDirExists;
  final bool isValid;
  
  const ValidationResult({
    required this.javaAvailable,
    required this.minecraftDirExists,
    required this.isValid,
  });
  
  @override
  String toString() {
    return 'ValidationResult(java: $javaAvailable, minecraftDir: $minecraftDirExists, valid: $isValid)';
  }
}