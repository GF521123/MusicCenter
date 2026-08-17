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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _init, child: const Text('重试')),
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

  void _onLogout() {
    setState(() => _authorized = false);
  }
}
