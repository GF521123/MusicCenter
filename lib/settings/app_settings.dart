import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 应用级设置持久化(如音乐文件存储来源)。
/// 复用安全存储:Windows DPAPI / Android Keystore / iOS Keychain。
class AppSettings {
  /// 音乐文件存储来源:云盘文件
  static const String sourceCloud = 'cloud';

  /// 音乐文件存储来源:本地文件(开发中)
  static const String sourceLocal = 'local';

  static const String _kStorageSource = 'app.storage_source';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 当前音乐文件存储来源,默认云盘文件
  Future<String> loadStorageSource() async =>
      (await _storage.read(key: _kStorageSource)) ?? sourceCloud;

  Future<void> saveStorageSource(String source) async =>
      _storage.write(key: _kStorageSource, value: source);
}
