import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../services/version_service.dart';

/// 启动参数构建工具
class LaunchArgsBuilder {
  /// 智能构建启动参数（自动检测版本类型）
  static List<String> buildArgs({
    required String versionPath,
    required String minecraftPath,
    required String username,
    int memory = 2048,
  }) {
    // 检测版本类型
    final isVanilla = VersionService.isVanillaVersion(versionPath);
    
    if (isVanilla) {
      return buildVanillaArgs(
        versionPath: versionPath,
        minecraftPath: minecraftPath,
        username: username,
        memory: memory,
      );
    } else {
      return buildModdedArgs(
        versionPath: versionPath,
        minecraftPath: minecraftPath,
        username: username,
        memory: memory,
      );
    }
  }
  
  /// 构建模组版启动参数
  static List<String> buildModdedArgs({
    required String versionPath,
    required String minecraftPath,
    required String username,
    int memory = 2048,
  }) {
    // 模组版使用相同的构建逻辑
    return buildVanillaArgs(
      versionPath: versionPath,
      minecraftPath: minecraftPath,
      username: username,
      memory: memory,
    );
  }
  /// 构建纯净版启动参数
  static List<String> buildVanillaArgs({
    required String versionPath,
    required String minecraftPath,
    required String username,
    int memory = 2048,
  }) {
    final List<String> args = [];
    
    // 读取版本JSON文件
    final jsonFile = File(VersionService.getVersionJsonPath(versionPath));
    final jsonContent = jsonFile.readAsStringSync();
    final versionData = jsonDecode(jsonContent) as Map<String, dynamic>;
    
    // JVM 基础参数
    args.addAll([
      '-Xmx${memory}M',
      '-Xms${memory}M',
    ]);
    
    // 从JSON中获取JVM参数
    final arguments = versionData['arguments'] as Map<String, dynamic>?;
    if (arguments != null) {
      final jvmArgs = arguments['jvm'] as List<dynamic>?;
      if (jvmArgs != null) {
        args.addAll(_processJvmArguments(jvmArgs, versionPath, minecraftPath));
      }
    }
    
    // 类路径
    args.addAll([
      '-cp',
      _buildClasspath(versionPath, minecraftPath),
      versionData['mainClass'] as String? ?? 'net.minecraft.client.main.Main',
    ]);
    
    // 游戏启动参数
    args.addAll(_buildGameArgs(
      versionPath: versionPath,
      minecraftPath: minecraftPath,
      username: username,
      versionData: versionData,
    ));
    
    return args;
  }
  
  /// 构建类路径
  static String _buildClasspath(String versionPath, String minecraftPath) {
    final List<String> classpathEntries = [];
    
    // 主 jar 文件
    final mainJar = VersionService.getVersionJarPath(versionPath);
    classpathEntries.add(mainJar);
    
    // 读取版本JSON文件来获取正确的依赖库列表
    final jsonFile = File(VersionService.getVersionJsonPath(versionPath));
    if (jsonFile.existsSync()) {
      try {
        final jsonContent = jsonFile.readAsStringSync();
        final versionData = jsonDecode(jsonContent) as Map<String, dynamic>;
        final libraries = versionData['libraries'] as List<dynamic>?;
        
        if (libraries != null) {
          _addLibrariesFromJson(libraries, minecraftPath, classpathEntries);
        }
      } catch (e) {
        // 如果JSON解析失败，回退到扫描所有jar文件
        print('警告: 无法解析版本JSON文件，回退到扫描所有库文件');
        final librariesDir = Directory(path.join(minecraftPath, 'libraries'));
        if (librariesDir.existsSync()) {
          _addJarsFromDirectory(librariesDir, classpathEntries);
        }
      }
    } else {
      // 如果没有JSON文件，扫描所有jar文件
      final librariesDir = Directory(path.join(minecraftPath, 'libraries'));
      if (librariesDir.existsSync()) {
        _addJarsFromDirectory(librariesDir, classpathEntries);
      }
    }
    
    return classpathEntries.join(Platform.isWindows ? ';' : ':');
  }
  
  /// 根据JSON文件添加依赖库
  static void _addLibrariesFromJson(List<dynamic> libraries, String minecraftPath, List<String> classpathEntries) {
    for (final library in libraries) {
      if (library is Map<String, dynamic>) {
        final name = library['name'] as String?;
        if (name != null) {
          // 检查规则，确定是否应该包含此库
          final rules = library['rules'] as List<dynamic>?;
          if (rules != null && !_shouldApplyLibraryRules(rules)) {
            continue;
          }
          
          // 构建库文件路径
          final libraryPath = _buildLibraryPath(name, minecraftPath);
          if (libraryPath != null && File(libraryPath).existsSync()) {
            classpathEntries.add(libraryPath);
          }
        }
      }
    }
  }
  
  /// 构建库文件路径
  static String? _buildLibraryPath(String name, String minecraftPath) {
    try {
      // 解析库名称格式: group:artifact:version[:classifier]
      final parts = name.split(':');
      if (parts.length < 3) return null;
      
      final group = parts[0].replaceAll('.', '/');
      final artifact = parts[1];
      final version = parts[2];
      final classifier = parts.length > 3 ? parts[3] : null;
      
      String filename = '$artifact-$version';
      if (classifier != null) {
        filename += '-$classifier';
      }
      filename += '.jar';
      
      return path.join(minecraftPath, 'libraries', group, artifact, version, filename);
    } catch (e) {
      return null;
    }
  }
  
  /// 检查库规则
  static bool _shouldApplyLibraryRules(List<dynamic> rules) {
    bool shouldInclude = true; // 默认包含
    
    for (final rule in rules) {
      if (rule is Map<String, dynamic>) {
        final action = rule['action'] as String?;
        final os = rule['os'] as Map<String, dynamic>?;
        
        bool ruleMatches = true;
        if (os != null) {
          final osName = os['name'] as String?;
          if (osName != null) {
            if (Platform.isMacOS && osName != 'osx') ruleMatches = false;
            if (Platform.isWindows && osName != 'windows') ruleMatches = false;
            if (Platform.isLinux && osName != 'linux') ruleMatches = false;
          }
        }
        
        if (ruleMatches) {
          if (action == 'allow') {
            shouldInclude = true;
          } else if (action == 'disallow') {
            shouldInclude = false;
          }
        }
      }
    }
    
    return shouldInclude;
  }
  
  /// 递归添加目录中的 jar 文件
  static void _addJarsFromDirectory(Directory dir, List<String> classpathEntries) {
    try {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.jar')) {
          classpathEntries.add(entity.path);
        }
      }
    } catch (e) {
      // 忽略扫描错误
    }
  }
  
  /// 处理JVM参数
  static List<String> _processJvmArguments(List<dynamic> jvmArgs, String versionPath, String minecraftPath) {
    final List<String> processedArgs = [];
    
    for (final arg in jvmArgs) {
      if (arg is String) {
        // 跳过-cp和${classpath}，因为我们会单独处理
        if (arg == '-cp' || arg == r'${classpath}') {
          continue;
        }
        
        // 替换模板变量
        String processedArg = arg;
        processedArg = processedArg.replaceAll(r'${natives_directory}', VersionService.getVersionNativesPath(versionPath));
        processedArg = processedArg.replaceAll(r'${launcher_name}', 'mc_launch');
        processedArg = processedArg.replaceAll(r'${launcher_version}', '1.0.0');
        
        processedArgs.add(processedArg);
      } else if (arg is Map<String, dynamic>) {
        // 处理条件参数
        final rules = arg['rules'] as List<dynamic>?;
        if (rules != null && _shouldApplyRules(rules)) {
          final value = arg['value'];
          if (value is String) {
            // 同样跳过-cp相关参数
            if (value == '-cp' || value == r'${classpath}') {
              continue;
            }
            
            String processedValue = value;
            processedValue = processedValue.replaceAll(r'${natives_directory}', VersionService.getVersionNativesPath(versionPath));
            processedValue = processedValue.replaceAll(r'${launcher_name}', 'mc_launch');
            processedValue = processedValue.replaceAll(r'${launcher_version}', '1.0.0');
            
            processedArgs.add(processedValue);
          } else if (value is List) {
            for (final item in value) {
              if (item is String && item != '-cp' && item != r'${classpath}') {
                String processedItem = item;
                processedItem = processedItem.replaceAll(r'${natives_directory}', VersionService.getVersionNativesPath(versionPath));
                processedItem = processedItem.replaceAll(r'${launcher_name}', 'mc_launch');
                processedItem = processedItem.replaceAll(r'${launcher_version}', '1.0.0');
                
                processedArgs.add(processedItem);
              }
            }
          }
        }
      }
    }
    
    return processedArgs;
  }
  
  /// 检查规则是否应该应用
  static bool _shouldApplyRules(List<dynamic> rules) {
    for (final rule in rules) {
      if (rule is Map<String, dynamic>) {
        final action = rule['action'] as String?;
        final os = rule['os'] as Map<String, dynamic>?;
        
        if (os != null) {
          final osName = os['name'] as String?;
          final osArch = os['arch'] as String?;
          
          bool osMatches = true;
          if (osName != null) {
            if (Platform.isMacOS && osName != 'osx') osMatches = false;
            if (Platform.isWindows && osName != 'windows') osMatches = false;
            if (Platform.isLinux && osName != 'linux') osMatches = false;
          }
          
          if (osArch != null) {
            // 简化架构检查
            // 可以根据需要添加更详细的架构检查
          }
          
          if (action == 'allow' && osMatches) {
            return true;
          } else if (action == 'disallow' && osMatches) {
            return false;
          }
        } else if (action == 'allow') {
          return true;
        }
      }
    }
    return false;
  }
  
  /// 构建游戏参数
  static List<String> _buildGameArgs({
    required String versionPath,
    required String minecraftPath,
    required String username,
    required Map<String, dynamic> versionData,
  }) {
    final List<String> gameArgs = [];
    final versionName = VersionService.getVersionNameFromPath(versionPath);
    
    // 从JSON中获取游戏参数模板
    final arguments = versionData['arguments'] as Map<String, dynamic>?;
    if (arguments != null) {
      final gameArguments = arguments['game'] as List<dynamic>?;
      if (gameArguments != null) {
        gameArgs.addAll(_processGameArguments(gameArguments, versionPath, minecraftPath, username, versionData));
      }
    }
    
    // 如果没有JSON参数，使用默认参数
    if (gameArgs.isEmpty) {
      final assetIndex = versionData['assetIndex'] as Map<String, dynamic>?;
      final assetId = assetIndex?['id'] as String? ?? versionName;
      
      gameArgs.addAll([
        '--username', username,
        '--version', versionName,
        '--gameDir', minecraftPath,
        '--assetsDir', path.join(minecraftPath, 'assets'),
        '--assetIndex', assetId,
        '--uuid', '00000000-0000-0000-0000-000000000000',
        '--accessToken', 'offline_token',
        '--clientId', '00000000-0000-0000-0000-000000000000',
        '--xuid', '0',
        '--userType', 'offline',
        '--versionType', 'release',
      ]);
    }
    
    return gameArgs;
  }
  
  /// 处理游戏参数
  static List<String> _processGameArguments(
    List<dynamic> gameArguments,
    String versionPath,
    String minecraftPath,
    String username,
    Map<String, dynamic> versionData,
  ) {
    final List<String> processedArgs = [];
    final versionName = VersionService.getVersionNameFromPath(versionPath);
    final assetIndex = versionData['assetIndex'] as Map<String, dynamic>?;
    final assetId = assetIndex?['id'] as String? ?? versionName;
    
    for (final arg in gameArguments) {
      if (arg is String) {
        // 替换模板变量
        String processedArg = arg;
        processedArg = processedArg.replaceAll(r'${auth_player_name}', username);
        processedArg = processedArg.replaceAll(r'${version_name}', versionName);
        processedArg = processedArg.replaceAll(r'${game_directory}', minecraftPath);
        processedArg = processedArg.replaceAll(r'${assets_root}', path.join(minecraftPath, 'assets'));
        processedArg = processedArg.replaceAll(r'${assets_index_name}', assetId);
        processedArg = processedArg.replaceAll(r'${auth_uuid}', '00000000-0000-0000-0000-000000000000');
        processedArg = processedArg.replaceAll(r'${auth_access_token}', 'offline_token');
        processedArg = processedArg.replaceAll(r'${clientid}', '00000000-0000-0000-0000-000000000000');
        processedArg = processedArg.replaceAll(r'${auth_xuid}', '0');
        processedArg = processedArg.replaceAll(r'${user_type}', 'offline');
        processedArg = processedArg.replaceAll(r'${version_type}', 'release');
        
        processedArgs.add(processedArg);
      } else if (arg is Map<String, dynamic>) {
        // 处理条件参数（如demo模式、自定义分辨率等）
        final rules = arg['rules'] as List<dynamic>?;
        if (rules != null) {
          // 对于测试，跳过所有条件参数以简化
          // 实际使用时可以根据需要实现特定功能
          continue;
        }
      }
    }
    
    return processedArgs;
  }
}