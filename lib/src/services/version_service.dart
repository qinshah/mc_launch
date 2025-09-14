import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

/// Minecraft 版本管理服务
class VersionService {
  
  /// 检测指定 .minecraft 路径下的所有游戏版本
  /// 
  /// 参数:
  /// - [minecraftPath]: .minecraft 文件夹路径
  /// - [includeModded]: 是否包含模组版本（默认 false）
  /// - [verbose]: 是否输出详细调试信息（默认 false）
  /// 
  /// 返回: 所有可用版本的完整路径列表
  static List<String> detectVersions(String minecraftPath, {bool includeModded = false, bool verbose = false}) {
    final versionsDir = Directory(path.join(minecraftPath, 'versions'));
    
    if (verbose) {
      print('正在检测版本目录: ${versionsDir.path}');
    }
    
    if (!versionsDir.existsSync()) {
      if (verbose) {
        print('版本目录不存在: ${versionsDir.path}');
      }
      return [];
    }
    
    final List<String> versionPaths = [];
    
    try {
      final entities = versionsDir.listSync();
      if (verbose) {
        print('找到 ${entities.length} 个条目');
      }
      
      for (final entity in entities) {
        if (entity is Directory) {
          final versionName = path.basename(entity.path);
          if (verbose) {
            print('检查版本目录: $versionName');
          }
          
          final jarFile = File(path.join(entity.path, '$versionName.jar'));
          final jsonFile = File(path.join(entity.path, '$versionName.json'));
          
          if (verbose) {
            print('  JAR 文件: ${jarFile.path} (存在: ${jarFile.existsSync()})');
            print('  JSON 文件: ${jsonFile.path} (存在: ${jsonFile.existsSync()})');
          }
          
          // 检查版本是否完整（需要有 jar 和 json 文件）
          if (jarFile.existsSync() && jsonFile.existsSync()) {
            // 根据参数决定是否过滤模组版本
            if (includeModded || isVanillaVersion(entity.path)) {
              versionPaths.add(entity.path);
              if (verbose) {
                print('  ✅ 添加版本: $versionName');
              }
            } else {
              if (verbose) {
                print('  ⚠️ 跳过模组版本: $versionName');
              }
            }
          } else {
            if (verbose) {
              print('  ❌ 版本不完整，缺少必要文件: $versionName');
            }
          }
        } else {
          if (verbose) {
            print('跳过非目录条目: ${entity.path}');
          }
        }
      }
    } catch (e) {
      if (verbose) {
        print('检测版本时发生错误: $e');
      }
      // 尝试使用不同的权限检查方式
      return _detectVersionsWithPermissionHandling(minecraftPath, includeModded, verbose);
    }
    
    if (verbose) {
      print('检测完成，找到 ${versionPaths.length} 个可用版本');
    }
    
    return versionPaths;
  }
  
  
  /// 使用权限处理的版本检测方法
  static List<String> _detectVersionsWithPermissionHandling(String minecraftPath, bool includeModded, bool verbose) {
    final List<String> versionPaths = [];
    
    try {
      // 尝试使用 shell 命令来列出目录内容（可能绕过某些权限问题）
      if (Platform.isMacOS || Platform.isLinux) {
        final versionsPath = path.join(minecraftPath, 'versions');
        
        if (verbose) {
          print('尝试使用系统命令检测版本...');
        }
        
        // 异步方式会阻塞，这里使用同步方式
        try {
          final result = Process.runSync('find', [versionsPath, '-maxdepth', '1', '-type', 'd', '-not', '-path', versionsPath]);
          
          if (result.exitCode == 0) {
            final lines = result.stdout.toString().trim().split('\n');
            
            for (final line in lines) {
              if (line.isNotEmpty) {
                final versionName = path.basename(line);
                final jarFile = File(path.join(line, '$versionName.jar'));
                final jsonFile = File(path.join(line, '$versionName.json'));
                
                if (jarFile.existsSync() && jsonFile.existsSync()) {
                  if (includeModded || isVanillaVersion(line)) {
                    versionPaths.add(line);
                    if (verbose) {
                      print('  ✅ 通过系统命令找到版本: $versionName');
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          if (verbose) {
            print('系统命令检测失败: $e');
          }
        }
      }
    } catch (e) {
      if (verbose) {
        print('权限处理检测失败: $e');
      }
    }
    
    return versionPaths;
  }
  
  /// 从版本路径中提取版本名称
  static String getVersionNameFromPath(String versionPath) {
    return path.basename(versionPath);
  }
  
  /// 获取版本的 jar 文件路径
  static String getVersionJarPath(String versionPath) {
    final versionName = getVersionNameFromPath(versionPath);
    return path.join(versionPath, '$versionName.jar');
  }
  
  /// 获取版本的 json 文件路径
  static String getVersionJsonPath(String versionPath) {
    final versionName = getVersionNameFromPath(versionPath);
    return path.join(versionPath, '$versionName.json');
  }
  
  /// 获取版本的 natives 文件夹路径
  static String getVersionNativesPath(String versionPath) {
    return path.join(versionPath, 'natives');
  }
  
  /// 检查是否为纯净版（非模组版本）
  static bool isVanillaVersion(String versionPath) {
    try {
      final jsonFile = File(getVersionJsonPath(versionPath));
      if (!jsonFile.existsSync()) return false;
      
      final jsonContent = jsonFile.readAsStringSync();
      final versionData = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      // 检查主类是否为 Minecraft 原生主类
      final mainClass = versionData['mainClass'] as String?;
      if (mainClass != 'net.minecraft.client.main.Main') {
        return false; // 模组版本通常有不同的主类
      }
      
      // 检查版本 ID 是否包含模组标识
      final versionId = versionData['id'] as String?;
      if (versionId != null) {
        // 常见的模组版本标识
        final modIndicators = ['forge', 'fabric', 'quilt', 'neoforge', 'modded'];
        for (final indicator in modIndicators) {
          if (versionId.toLowerCase().contains(indicator)) {
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      // 如果解析失败，认为不是纯净版
      return false;
    }
  }
}