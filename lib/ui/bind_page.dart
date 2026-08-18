import 'package:flutter/material.dart';

import '../cloud/aliyun/aliyun_drive.dart';
import '../cloud/cloud_exception.dart';

/// 绑定云盘页:粘贴 refresh_token 直连授权
/// (官方 2025-07 起暂停个人开发者申请,不再走注册应用 + 浏览器授权)
class BindPage extends StatefulWidget {
  final AliyunDrive drive;
  final VoidCallback onBound;

  const BindPage({super.key, required this.drive, required this.onBound});

  @override
  State<BindPage> createState() => _BindPageState();
}

class _BindPageState extends State<BindPage> {
  final TextEditingController _tokenController = TextEditingController();
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _bind() async {
    final refreshToken = _tokenController.text.trim();
    if (refreshToken.isEmpty) {
      _showError('请先粘贴 refresh_token');
      return;
    }
    setState(() {
      _busy = true;
      _status = '正在验证并换取访问凭证...';
    });
    try {
      await widget.drive.bindWithRefreshToken(refreshToken);
      if (!mounted) return;
      widget.onBound();
    } on CloudException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('绑定失败:$e');
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
          constraints: const BoxConstraints(maxWidth: 560),
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
                '粘贴 refresh_token 即可直连,无需注册开发者应用',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _tokenController,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: 'refresh_token',
                  hintText: '粘贴阿里云盘网页版获取的 refresh_token',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _busy ? null : _bind,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(_busy ? '绑定中...' : '保存并绑定'),
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
                '获取 refresh_token(约 1 分钟)\n'
                '1. 浏览器打开 www.alipan.com 并登录\n'
                '2. 按 F12 打开开发者工具 → 顶部选 "应用 / Application"\n'
                '3. 左侧 "本地存储 / Local Storage" → 点 https://www.alipan.com\n'
                '4. 找到键 token,展开其 JSON,复制 refresh_token 的值粘贴到上方\n\n'
                '提示:refresh_token 长期有效;应用会定期用它自动换取新 token,无需重复操作。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
