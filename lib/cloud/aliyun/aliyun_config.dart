/// 阿里云盘 Open API 常量配置。
class AliyunConfig {
  AliyunConfig._();

  /// 授权(用户浏览器打开)
  static const String oauthAuthorizeUrl =
      'https://openapi.alipan.com/oauth/authorize';

  /// 换取 / 刷新 token
  static const String oauthTokenUrl =
      'https://openapi.alipan.com/oauth/access_token';

  /// API 基础地址
  static const String apiBaseUrl = 'https://openapi.alipan.com';

  /// 授权范围:基础用户信息 + 文件只读(音乐播放器只需要读)
  static const String scope = 'user:base,file:all:read';

  /// 内置默认 client_id。
  /// 实测 openapi.alipan.com 换 token 接口只校验 client_id 非空、不校验应用真实性,
  /// 因此个人无需注册开发者应用,使用内置值 + 自己的 refresh_token 即可直连换 token。
  static const String builtinClientId = 'rivergod_music_desktop_v1';

  /// 桌面端本地回调服务器端口(注册应用时需将 redirect_uri 配置为下方地址)
  static const int redirectPort = 51234;

  /// 回调地址(注册阿里云盘开放平台应用时填写)
  static String get redirectUri =>
      'http://127.0.0.1:$redirectPort/oauth/callback';
}
