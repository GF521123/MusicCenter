/// 阿里云盘 OAuth 凭据配置(客户端注册信息)
class ClientConfig {
  final String clientId;
  final String clientSecret;

  const ClientConfig({required this.clientId, required this.clientSecret});
}

/// OAuth Token(access + refresh)
class AliyunToken {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  /// 有效秒数
  final int expiresIn;

  final String? scope;
  final String? userId;

  const AliyunToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    this.scope,
    this.userId,
  });

  /// 过期时间(预留 60 秒余量,避免临界失效)
  DateTime get expiresAt =>
      DateTime.now().add(Duration(seconds: expiresIn - 60));

  factory AliyunToken.fromJson(Map<String, dynamic> json) => AliyunToken(
        accessToken: json['access_token']?.toString() ?? '',
        refreshToken: json['refresh_token']?.toString() ?? '',
        tokenType: json['token_type']?.toString() ?? 'Bearer',
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 7200,
        scope: json['scope']?.toString(),
        userId: json['user_id']?.toString(),
      );
}

/// 已持久化的 token(含过期时间)
class StoredToken {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const StoredToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });
}
