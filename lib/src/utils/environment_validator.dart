import 'dart:io';

/// 环境验证工具
class EnvironmentValidator {
  /// 验证 Java 环境
  static Future<bool> validateJava() async {
    // 尝试常见的 Java 路径
    final javaPaths = [
      'java', // 系统 PATH 中的 java
      '/usr/bin/java',
      '/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java',
    ];
    
    for (final javaPath in javaPaths) {
      try {
        final result = await Process.run(javaPath, ['-version']);
        if (result.exitCode == 0) {
          return true;
        }
      } catch (e) {
        // 继续尝试下一个路径
      }
    }
    
    return false;
  }
  
  /// 验证 .minecraft 目录
  static bool validateMinecraftDir(String minecraftPath) {
    final minecraftDir = Directory(minecraftPath);
    return minecraftDir.existsSync();
  }
  
  /// 完整环境验证
  static Future<ValidationResult> validateEnvironment(String minecraftPath) async {
    final javaValid = await validateJava();
    final minecraftDirValid = validateMinecraftDir(minecraftPath);
    
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