/// 云盘统一数据模型,所有云盘实现(阿里/百度)共用的公共类型。
/// 云盘中的文件 / 文件夹
class CloudFile {
  final String fileId;
  final String name;
  final String parentFileId;

  /// 'folder' 或 'file'
  final String type;

  /// 文件分类:audio / video / image / doc / ...
  final String? category;

  final int size;
  final DateTime? updatedAt;
  final String? thumbnail;

  /// 内容哈希(阿里云盘可用于秒传/去重)
  final String? contentHash;

  const CloudFile({
    required this.fileId,
    required this.name,
    required this.parentFileId,
    required this.type,
    this.category,
    this.size = 0,
    this.updatedAt,
    this.thumbnail,
    this.contentHash,
  });

  bool get isFolder => type == 'folder';

  factory CloudFile.fromJson(Map<String, dynamic> json) => CloudFile(
        fileId: json['file_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        parentFileId: json['parent_file_id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'file',
        category: json['category']?.toString(),
        size: (json['size'] as num?)?.toInt() ?? 0,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
        thumbnail: json['thumbnail']?.toString(),
        contentHash: json['content_hash']?.toString(),
      );

  /// 文件大小的人类可读格式(音乐列表展示用)
  String get sizeText {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}

/// 云盘分页结果
class CloudPage<T> {
  final List<T> items;

  /// 下一页游标;为空表示已无更多
  final String? nextMarker;

  const CloudPage({required this.items, this.nextMarker});

  bool get hasMore => nextMarker != null && nextMarker!.isNotEmpty;
}

/// 云盘用户信息
class CloudUserInfo {
  final String userId;
  final String name;
  final String defaultDriveId;

  const CloudUserInfo({
    required this.userId,
    required this.name,
    required this.defaultDriveId,
  });
}
