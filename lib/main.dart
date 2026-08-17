import 'package:flutter/material.dart';

import 'cloud/aliyun/aliyun_drive.dart';
import 'ui/bind_page.dart';
import 'ui/browse_page.dart';

void main() {
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '云盘音乐',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
      ),
      home: const HomePage(),
    );
  }
}

/// 入口页:根据授权状态进入 绑定页 / 浏览页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AliyunDrive _drive = AliyunDrive();
  bool _loading = true;
  bool _authorized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _drive.init();
      final ok = await _drive.isAuthorized();
      if (!mounted) return;
      setState(() {
        _authorized = ok;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _init, child: const Text('重试')),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _resetBinding,
                child: const Text('清除本地授权,重新绑定'),
              ),
            ],
          ),
        ),
      );
    }
    if (_authorized) {
      return BrowsePage(drive: _drive, onLogout: _onLogout);
    }
    return BindPage(drive: _drive, onBound: _onBound);
  }

  void _onBound() {
    setState(() => _authorized = true);
  }

  /// 授权状态损坏时,允许用户清除本地凭据回到绑定页
  Future<void> _resetBinding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除本地授权'),
        content: const Text('将清除本地保存的登录凭据,之后需要重新授权云盘才能继续使用。确定继续吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('清除并重新绑定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _drive.logout();
    } catch (_) {
      // 清除失败也继续,避免卡死在错误页
    }
    if (!mounted) return;
    setState(() {
      _error = null;
      _authorized = false;
    });
  }

  void _onLogout() {
    setState(() => _authorized = false);
  }
}
