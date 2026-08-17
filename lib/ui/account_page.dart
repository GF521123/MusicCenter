import 'package:flutter/material.dart';

import '../cloud/cloud_drive.dart';
import '../settings/app_settings.dart';

/// 账户信息页:展示当前云盘账号信息,并选择音乐文件存储来源。
class AccountPage extends StatefulWidget {
  final CloudDrive drive;
  final VoidCallback? onLogout;

  const AccountPage({super.key, required this.drive, this.onLogout});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AppSettings _settings = AppSettings();

  bool _loading = true;
  String? _error;
  String _userName = '';
  String _userId = '';
  String _driveId = '';

  /// 当前存储来源:cloud(云盘文件)/ local(本地文件)
  String _source = AppSettings.sourceCloud;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final source = await _settings.loadStorageSource();
      final info = await widget.drive.getUserInfo();
      if (!mounted) return;
      setState(() {
        _source = source;
        _userName = info.name;
        _userId = info.userId;
        _driveId = info.defaultDriveId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _changeSource(String source) async {
    if (source == _source) return;
    setState(() => _source = source);
    await _settings.saveStorageSource(source);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          source == AppSettings.sourceCloud
              ? '音乐文件来源已切换为:云盘文件'
              : '音乐文件来源已切换为:本地文件',
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await widget.drive.logout();
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账户信息')),
      body: _buildBody(),
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
            OutlinedButton(onPressed: _init, child: const Text('重试')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAccountCard(),
        const SizedBox(height: 24),
        Text(
          '音乐文件存储',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '选择音乐文件的存储位置,将决定从哪里加载音乐库',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              RadioListTile<String>(
                value: AppSettings.sourceCloud,
                groupValue: _source,
                onChanged: (v) => _changeSource(v!),
                secondary: const Icon(Icons.cloud_outlined),
                title: const Text('云盘文件'),
                subtitle: const Text('音乐文件存储在云盘文件夹,授权后可直接边下边播 / 在线播放,不占本地空间'),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                value: AppSettings.sourceLocal,
                groupValue: _source,
                onChanged: (v) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('本地文件存储开发中,敬请期待')),
                  );
                },
                secondary: const Icon(Icons.folder_outlined),
                title: const Text('本地文件'),
                subtitle: const Text('从本地磁盘文件夹加载音乐(开发中)'),
              ),
            ],
          ),
        ),
        if (_source == AppSettings.sourceCloud) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '当前存储为云盘文件:绑定云盘并选中文件夹后,该文件夹将作为音乐库来源。可在云盘目录中浏览并选择音乐文件夹。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('注销账号'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 32,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              widget.drive.name,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              _userName.isEmpty ? '未获取到用户名' : _userName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _kv('用户 ID', _userId),
            _kv('云盘 ID', _driveId),
            _kv('账号状态', '已授权'),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(k, style: const TextStyle(color: Colors.grey)),
            ),
            Expanded(
              child: SelectableText(
                v.isEmpty ? '-' : v,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
}
