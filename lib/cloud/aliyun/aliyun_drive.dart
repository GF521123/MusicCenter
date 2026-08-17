import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

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
/// 授权方式(Windows 首发):
/// 1. 启动本地回调服务器(127.0.0.1:51234)
/// 2. 打开系统浏览器跳转授权页
/// 3. 用户授权后平台回调本地服务器,捕获 code
/// 4. 用 code 换取 token 并安全存储
///
/// 注:移动端(Android/iOS)后期改用自定义 scheme 回调。
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

  @override
  Future<void> authorize() async {
    final config = await _store.loadClientConfig();
    if (config == null) {
      throw const CloudException('请先在设置中配置 Client ID / Client Secret');
    }
    final code = await _startLocalCallbackServer(config);
    final token = await _oauth.exchangeCode(
      code: code,
      clientId: config.clientId,
      clientSecret: config.clientSecret,
    );
    await _store.saveToken(token);
    _accessToken = token.accessToken;
  }

  /// 启动本地回调服务器并打开浏览器,等待授权码
  Future<String> _startLocalCallbackServer(ClientConfig config) async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      AliyunConfig.redirectPort,
    );
    try {
      final url = await _oauth.buildAuthorizeUrl(
        clientId: config.clientId,
        redirectUri: AliyunConfig.redirectUri,
      );
      try {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        // 浏览器打开失败不阻塞,提示用户手动打开
        throw CloudException('无法自动打开浏览器,请手动访问:$url');
      }
      // 等待授权回调,2 分钟无响应视为超时,避免页面一直转圈
      return await _waitForCallback(server).timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw const CloudException('授权等待超时,请重新发起授权'),
      );
    } finally {
      await server.close(force: true);
    }
  }

  Future<String> _waitForCallback(HttpServer server) {
    final completer = Completer<String>();
    server.listen((request) {
      final uri = request.uri;
      if (uri.path == '/oauth/callback') {
        final code = uri.queryParameters['code'];
        final error = uri.queryParameters['error'];
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.html;
        if (code != null && code.isNotEmpty) {
          request.response.write(
            '<html><head><meta charset="utf-8"></head>'
            '<body style="font-family:sans-serif;text-align:center;margin-top:100px;">'
            '<h2>授权成功</h2><p>可以关闭此页面,返回应用。</p>'
            '</body></html>',
          );
          completer.complete(code);
        } else {
          final desc = error ?? '未知错误';
          request.response.write(
            '<html><head><meta charset="utf-8"></head>'
            '<body style="font-family:sans-serif;text-align:center;margin-top:100px;">'
            '<h2>授权失败</h2><p>$desc</p>'
            '</body></html>',
          );
          completer.completeError(CloudException('授权失败:$desc'));
        }
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not Found');
      }
      request.response.close();
    });
    return completer.future;
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
    if (config == null) {
      throw const CloudException('缺少 Client 配置,请重新绑定云盘');
    }
    final newToken = await _oauth.refreshToken(
      refreshToken: token.refreshToken,
      clientId: config.clientId,
      clientSecret: config.clientSecret,
    );
    await _store.saveToken(newToken);
    _accessToken = newToken.accessToken;
  }
}
