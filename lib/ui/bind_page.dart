import 'package:flutter/material.dart';

import '../cloud/aliyun/aliyun_drive.dart';
import '../cloud/aliyun/aliyun_models.dart';
import '../cloud/aliyun/aliyun_token_store.dart';
import '../cloud/cloud_exception.dart';

/// 绑定云盘页:配置 Client ID / Secret 并发起授权
class BindPage extends StatefulWidget {
  final AliyunDrive drive;
  final VoidCallback onBound;

  const BindPage({super.key, required this.drive, required this.onBound});

  @override
  State<BindPage> createState() => _BindPageState();
}

class _BindPageState extends State<BindPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();
  final AliyunTokenStore _store = AliyunTokenStore();
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _idController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _store.loadClientConfig();
      if (config != null) {
        _idController.text = config.clientId;
        _secretController.text = config.clientSecret;
      }
    } catch (_) {
      // 读取本地配置失败时保持空输入,让用户手动填写
    }
  }

  Future<void> _authorize() async {
    final id = _idController.text.trim();
    final secret = _secretController.text.trim();
    if (id.isEmpty || secret.isEmpty) {
      _showError('请填写 Client ID 与 Client Secret');
      return;
    }
    setState(() {
      _busy = true;
      _status = '正在打开授权页面...';
    });
    try {
      await _store.saveClientConfig(
        ClientConfig(clientId: id, clientSecret: secret),
      );
      await widget.drive.init();
      await widget.drive.authorize();
      if (!mounted) return;
      widget.onBound();
    } on CloudException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('授权失败:$e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
        });
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _status = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('绑定阿里云盘')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              const Icon(Icons.cloud_outlined, size: 64, color: Colors.blueGrey),
              const SizedBox(height: 12),
              Text(
                '云盘音乐',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                '首次使用需授权阿里云盘,请先注册开放平台应用',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Client ID',
                  hintText: '开放平台应用 Client ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _secretController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Client Secret',
                  hintText: '开放平台应用 Client Secret',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _busy ? null : _authorize,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(_busy ? '授权中...' : '保存并授权'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '注册指引\n1. 访问阿里云盘开放平台(www.aliyundrive.com/developer)创建应用\n'
                '2. 授权回调地址(redirect_uri)填写:\nhttp://127.0.0.1:51234/oauth/callback\n'
                '3. 申请 file:all:read 只读权限',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
