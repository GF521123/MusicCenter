import 'package:flutter/material.dart';

import '../cloud/cloud_drive.dart';
import '../cloud/cloud_models.dart';
import 'account_page.dart';

/// 云盘目录浏览页(M1:浏览文件夹、定位音乐文件)
class BrowsePage extends StatefulWidget {
  final CloudDrive drive;
  final VoidCallback? onLogout;

  const BrowsePage({super.key, required this.drive, this.onLogout});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  /// 已进入的文件夹栈(根目录为空栈)
  final List<CloudFile> _folderStack = [];
  List<CloudFile> _files = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _nextMarker;
  String? _error;
  String _userName = '';

  String get _currentParentId =>
      _folderStack.isEmpty ? 'root' : _folderStack.last.fileId;

  String get _breadcrumb {
    if (_folderStack.isEmpty) return '全部文件';
    return _folderStack.map((f) => f.name).join(' / ');
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFiles(reset: true);
  }

  Future<void> _loadUser() async {
    try {
      final info = await widget.drive.getUserInfo();
      if (mounted) setState(() => _userName = info.name);
    } catch (_) {
      // 用户信息获取失败不阻塞浏览
    }
  }

  Future<void> _loadFiles({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await widget.drive
          .listFolder(_currentParentId, marker: reset ? null : _nextMarker);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _files = page.items;
        } else {
          _files = [..._files, ...page.items];
        }
        _nextMarker = page.nextMarker;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = '$e';
      });
    }
  }

  void _enterFolder(CloudFile folder) {
    setState(() => _folderStack.add(folder));
    _loadFiles(reset: true);
  }

  void _goBack() {
    if (_folderStack.isEmpty) return;
    setState(() => _folderStack.removeLast());
    _loadFiles(reset: true);
  }

  Future<void> _onFileTap(CloudFile file) async {
    final url = await widget.drive.getDownloadUrl(file.fileId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(file.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _kv('大小', file.sizeText),
              if (file.category != null) _kv('类型', file.category!),
              _kv('文件 ID', file.fileId),
              const SizedBox(height: 8),
              SelectableText(url, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 80, child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Future<void> _logout() async {
    await widget.drive.logout();
    widget.onLogout?.call();
  }

  Future<void> _openAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountPage(
          drive: widget.drive,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_breadcrumb, overflow: TextOverflow.ellipsis),
        leading: _folderStack.isEmpty
            ? null
            : IconButton(
                tooltip: '上一级',
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => _loadFiles(reset: true),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '账户信息',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: _openAccount,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('注销账号')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_userName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_userName, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _loadFiles(reset: true),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_files.isEmpty) {
      return const Center(child: Text('文件夹为空'));
    }
    return Scrollbar(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            if (_nextMarker != null && !_loadingMore && !_loading) {
              _loadFiles(reset: false);
            }
          }
          return false;
        },
        child: ListView.builder(
          itemCount: _files.length + (_nextMarker != null ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _files.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _buildItem(_files[index]);
          },
        ),
      ),
    );
  }

  Widget _buildItem(CloudFile file) {
    if (file.isFolder) {
      return ListTile(
        leading: const Icon(Icons.folder, color: Colors.amber),
        title: Text(file.name),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _enterFolder(file),
      );
    }
    final isAudio = file.category == 'audio';
    return ListTile(
      leading: Icon(
        isAudio ? Icons.music_note : Icons.insert_drive_file,
        color: isAudio ? Colors.blue : Colors.grey,
      ),
      title: Text(file.name),
      subtitle: Text(file.sizeText),
      onTap: () => _onFileTap(file),
    );
  }
}
