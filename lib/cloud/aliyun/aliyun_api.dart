import 'package:dio/dio.dart';

import 'aliyun_config.dart';
import '../cloud_exception.dart';
import '../cloud_models.dart';

/// 阿里云盘 Open API 封装(业务接口,不含 OAuth)
class AliyunOpenApi {
  final Dio _dio;

  /// 认证失效(401)时由驱动注入的刷新回调;刷新完成后自动重试一次
  Future<void> Function()? onAuthError;

  AliyunOpenApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AliyunConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  Options _auth(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  /// 401 时触发刷新回调并用新凭据重试一次;重试请求不再触发刷新,
  /// 防止「刷新成功但请求仍 401」时陷入无限重试循环
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && onAuthError != null) {
        await onAuthError!();
        return await _guardOnce(request);
      }
      rethrow;
    }
  }

  /// 仅执行一次请求,直接透传异常,不再触发 401 刷新回调
  Future<T> _guardOnce<T>(Future<T> Function() request) => request();

  /// 获取用户信息(含 default_drive_id)
  Future<CloudUserInfo> getUserInfo(String accessToken) {
    return _guard(() async {
      final resp = await _dio.get(
        '/adrive/v1.0/user/getUserInfo',
        options: _auth(accessToken),
      );
      final data = _asMap(resp.data, '获取用户信息失败');
      return CloudUserInfo(
        userId: data['user_id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        defaultDriveId: data['default_drive_id']?.toString() ?? '',
      );
    });
  }

  /// 列出文件夹内容(分页,limit 最大 100)
  Future<CloudPage<CloudFile>> listFiles({
    required String accessToken,
    required String driveId,
    required String parentFileId,
    String? marker,
    int limit = 100,
  }) {
    return _guard(() async {
      final resp = await _dio.post(
        '/adrive/v1.0/openFile/list',
        data: {
          'drive_id': driveId,
          'parent_file_id': parentFileId,
          'limit': limit,
          if (marker != null) 'marker': marker,
          'order_by': 'name',
          'order_direction': 'ASC',
          'fields': '*',
        },
        options: _auth(accessToken),
      );
      final data = _asMap(resp.data, '获取文件列表失败');
      final items = (data['items'] as List<dynamic>? ?? const [])
          .map((e) => CloudFile.fromJson(_asMap(e, '文件数据异常')))
          .toList();
      return CloudPage<CloudFile>(
        items: items,
        nextMarker: _nullIfEmpty(data['next_marker']?.toString()),
      );
    });
  }

  /// 获取文件下载链接(仅对 file 有效,有有效期)
  Future<String> getDownloadUrl({
    required String accessToken,
    required String driveId,
    required String fileId,
    int expireSec = 3600,
  }) {
    return _guard(() async {
      final resp = await _dio.post(
        '/adrive/v1.0/openFile/getDownloadUrl',
        data: {
          'drive_id': driveId,
          'file_id': fileId,
          'expire_sec': expireSec,
        },
        options: _auth(accessToken),
      );
      final data = _asMap(resp.data, '获取下载链接失败');
      final url = data['url']?.toString();
      if (url == null || url.isEmpty) {
        throw const CloudException('下载链接为空');
      }
      return url;
    });
  }

  String? _nullIfEmpty(String? s) =>
      (s == null || s.isEmpty) ? null : s;

  Map<String, dynamic> _asMap(dynamic data, String fallbackMsg) {
    if (data is! Map<String, dynamic>) {
      throw CloudException(fallbackMsg);
    }
    final code = data['code'];
    final msg = data['message']?.toString();
    if (code != null && code.toString() != '0' && code.toString() != '200') {
      throw CloudException(msg ?? '接口错误:$code', code: _tryInt(code));
    }
    return data;
  }

  int? _tryInt(Object? code) {
    if (code is int) return code;
    return int.tryParse(code?.toString() ?? '');
  }
}
