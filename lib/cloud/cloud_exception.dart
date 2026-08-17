/// 云盘统一异常,UI 层统一展示 message。
class CloudException implements Exception {
  final String message;

  /// 可选错误码(如 HTTP 状态码 / 云盘平台错误码)
  final int? code;

  const CloudException(this.message, {this.code});

  @override
  String toString() => code != null ? 'CloudException($code): $message' : 'CloudException: $message';
}
