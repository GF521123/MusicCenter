import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'aliyun_models.dart';

/// Token 与 Client 配置的安全持久化。
/// 平台底层:Windows DPAPI / Android Keystore / iOS Keychain。
class AliyunTokenStore {
  static const String _kClientId = 'aliyun.client_id';
  static const String _kClientSecret = 'aliyun.client_secret';
  static const String _kAccessToken = 'aliyun.access_token';
  static const String _kRefreshToken = 'aliyun.refresh_token';
  static const String _kExpiresAt = 'aliyun.expires_at';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 保存应用注册信息(Client ID / Secret)
  Future<void> saveClientConfig(ClientConfig config) async {
    await _storage.write(key: _kClientId, value: config.clientId);
    await _storage.write(key: _kClientSecret, value: config.clientSecret);
  }

  Future<ClientConfig?> loadClientConfig() async {
    final id = await _storage.read(key: _kClientId);
    final secret = await _storage.read(key: _kClientSecret);
    if (id == null || id.isEmpty || secret == null || secret.isEmpty) {
      return null;
    }
    return ClientConfig(clientId: id, clientSecret: secret);
  }

  /// 保存 token
  Future<void> saveToken(AliyunToken token) async {
    await _storage.write(key: _kAccessToken, value: token.accessToken);
    await _storage.write(key: _kRefreshToken, value: token.refreshToken);
    await _storage.write(
      key: _kExpiresAt,
      value: token.expiresAt.millisecondsSinceEpoch.toString(),
    );
  }

  Future<StoredToken?> loadToken() async {
    final access = await _storage.read(key: _kAccessToken);
    final refresh = await _storage.read(key: _kRefreshToken);
    final expiresAt = await _storage.read(key: _kExpiresAt);
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty ||
        expiresAt == null) {
      return null;
    }
    return StoredToken(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(int.parse(expiresAt)),
    );
  }

  /// 清除全部阿里云盘本地数据(注销)
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
