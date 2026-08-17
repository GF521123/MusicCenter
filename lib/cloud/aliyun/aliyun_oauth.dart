import 'package:dio/dio.dart';

import 'aliyun_config.dart';
import 'aliyun_models.dart';
import '../cloud_exception.dart';

/// 阿里云盘 OAuth 2.0 流程(授权 URL 生成 / 换 token / 刷新 token)
class AliyunOAuth {
  final Dio _dio;

  AliyunOAuth({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AliyunConfig.oauthTokenUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  /// 生成授权 URL(浏览器打开)
  Future<String> buildAuthorizeUrl({
    required String clientId,
    required String redirectUri,
    String? state,
  }) async {
    final uri = Uri.parse(AliyunConfig.oauthAuthorizeUrl).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': AliyunConfig.scope,
        'response_type': 'code',
        if (state != null) 'state': state,
      },
    );
    return uri.toString();
  }

  /// 用授权码换取 token
  Future<AliyunToken> exchangeCode({
    required String code,
    required String clientId,
    required String clientSecret,
  }) async {
    final resp = await _dio.post(
      '',
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    return _parseToken(resp.data);
  }

  /// 刷新 token
  Future<AliyunToken> refreshToken({
    required String refreshToken,
    required String clientId,
    required String clientSecret,
  }) async {
    final resp = await _dio.post(
      '',
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    return _parseToken(resp.data);
  }

  AliyunToken _parseToken(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const CloudException('Token 响应格式异常');
    }
    final error = data['error']?.toString();
    final message = data['message']?.toString() ?? data['error_description']?.toString();
    if (error != null || data['access_token'] == null) {
      throw CloudException(message ?? '授权失败:$error', code: error != null ? -1 : null);
    }
    return AliyunToken.fromJson(data);
  }
}
