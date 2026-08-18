import 'aliyun_api.dart';
import 'aliyun_config.dart';
import 'aliyun_models.dart';
import 'aliyun_oauth.dart';
import 'aliyun_token_store.dart';
import '../cloud_drive.dart';
import '../cloud_exception.dart';
import '../cloud_models.dart';

/// 阿里云盘实现。
///
/// 授权方式(2025-07 起官方暂停个人开发者申请,不再走注册应用的浏览器授权):
/// 1. 用户在网页版(www.alipan.com)F12 中取到自己的 refresh_token
/// 2. 在绑定页粘贴 refresh_token,app 用内置 client_id(接口仅校验非空)直连换 token
/// 3. token 过期后用 refresh_token 自动刷新
class AliyunDrive implements CloudDrive {
  final AliyunTokenStore _store;
  final AliyunOAuth _oauth;
  final AliyunOpenApi _api;

  String? _accessToken;
  String? _driveId;

  AliyunDrive({AliyunTokenStore? store, AliyunOAuth? oauth, AliyunOpenApi? api})
      : _store = store ?? AliyunTokenStore(),
        _oauth = oauth ?? AliyunOAuth(),
        _api = api ?? AliyunOpenApi() {
    _api.onAuthError = _onApiAuthError;
  }

  @override
  String get name => '阿里云盘';

  @override
  Future<void> init() async {
    _accessToken = null;
    _driveId = null;
    final token = await _store.loadToken();
    if (token != null) {
      if (token.expiresAt.isBefore(DateTime.now())) {
        await _refresh(token);
      } else {
        _accessToken = token.accessToken;
      }
    }
  }

  @override
  Future<bool> isAuthorized() async {
    if (_accessToken != null) return true;
    final token = await _store.loadToken();
    return token != null;
  }

  /// 用 refresh_token 直连换取 token(无需注册开发者应用)。
  /// [clientId] 留空时使用内置默认值。
  Future<void> bindWithRefreshToken(String refreshToken,
      {String? clientId}) async {
    if (refreshToken.trim().isEmpty) {
      throw const CloudException('refresh_token 不能为空');
    }
    final id = (clientId == null || clientId.isEmpty)
        ? AliyunConfig.builtinClientId
        : clientId;
    // 先保存配置,确保后续刷新可用
    await _store.saveClientConfig(ClientConfig(clientId: id));
    final token = await _oauth.refreshToken(
      refreshToken: refreshToken.trim(),
      clientId: id,
    );
    await _store.saveToken(token);
    _accessToken = token.accessToken;
    _driveId = null;
  }

  /// 兼容旧入口:读取本地 refresh_token 刷新(若已绑定过)。
  /// 新绑定流程请使用 [bindWithRefreshToken]。
  @override
  Future<void> authorize() async {
    final token = await _store.loadToken();
    if (token == null || token.refreshToken.isEmpty) {
      throw const CloudException('请先在绑定页粘贴 refresh_token');
    }
    await bindWithRefreshToken(token.refreshToken);
  }

  @override
  Future<void> logout() async {
    await _store.clear();
    _accessToken = null;
    _driveId = null;
  }

  @override
  Future<CloudUserInfo> getUserInfo() async {
    await _ensureToken();
    final info = await _api.getUserInfo(_accessToken!);
    _driveId ??= info.defaultDriveId;
    return info;
  }

  @override
  Future<CloudPage<CloudFile>> listFolder(String parentId,
      {String? marker}) async {
    await _ensureToken();
    await _ensureDriveId();
    return _api.listFiles(
      accessToken: _accessToken!,
      driveId: _driveId!,
      parentFileId: parentId,
      marker: marker,
    );
  }

  @override
  Future<String> getDownloadUrl(String fileId) async {
    await _ensureToken();
    await _ensureDriveId();
    return _api.getDownloadUrl(
      accessToken: _accessToken!,
      driveId: _driveId!,
      fileId: fileId,
    );
  }

  /// API 返回 401:丢弃内存 token,重新加载/刷新后由 API 层自动重试
  Future<void> _onApiAuthError() async {
    _accessToken = null;
    await _ensureToken();
  }

  /// 确保 access token 有效,过期自动刷新
  Future<void> _ensureToken() async {
    if (_accessToken != null) return;
    final token = await _store.loadToken();
    if (token == null) {
      throw const CloudException('未授权,请先绑定云盘');
    }
    if (token.expiresAt.isBefore(DateTime.now())) {
      await _refresh(token);
    } else {
      _accessToken = token.accessToken;
    }
  }

  Future<void> _ensureDriveId() async {
    if (_driveId != null) return;
    final info = await _api.getUserInfo(_accessToken!);
    if (info.defaultDriveId.isEmpty) {
      throw const CloudException('未能获取云盘 drive_id');
    }
    _driveId = info.defaultDriveId;
  }

  /// 正在进行的刷新任务:并发场景共享同一次刷新,避免重复请求
  Future<void>? _refreshFuture;

  Future<void> _refresh(StoredToken token) {
    return _refreshFuture ??=
        _doRefresh(token).whenComplete(() => _refreshFuture = null);
  }

  Future<void> _doRefresh(StoredToken token) async {
    final config = await _store.loadClientConfig();
    final clientId = config?.clientId ?? AliyunConfig.builtinClientId;
    final newToken = await _oauth.refreshToken(
      refreshToken: token.refreshToken,
      clientId: clientId,
      clientSecret: config?.clientSecret,
    );
    await _store.saveToken(newToken);
    _accessToken = newToken.accessToken;
  }
}
