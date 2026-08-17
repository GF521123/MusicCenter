import 'cloud_models.dart';

/// 云盘统一抽象接口。
/// UI 只依赖该抽象,新增云盘(如百度云)只需实现此接口。
abstract class CloudDrive {
  /// 云盘显示名称
  String get name;

  /// 初始化(读取本地凭据、判断授权状态、必要时刷新 token)
  Future<void> init();

  /// 是否已授权
  Future<bool> isAuthorized();

  /// 发起授权流程(桌面端:拉起本地回调服务器 + 系统浏览器)
  Future<void> authorize();

  /// 注销(清除本地凭据)
  Future<void> logout();

  /// 获取当前用户信息
  Future<CloudUserInfo> getUserInfo();

  /// 列出文件夹内容(parentId 传 'root' 表示根目录,支持分页)
  Future<CloudPage<CloudFile>> listFolder(String parentId, {String? marker});

  /// 获取文件可播放的下载链接(有有效期,播放前动态获取)
  Future<String> getDownloadUrl(String fileId);
}
