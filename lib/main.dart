import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'dart:io';

void main() => runApp(const MyApp());

const String API = "http://47.114.49.46/api/activate";
const String SECRET = "hco02476589310kallpxh315onion.9246fnziw";

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stella Polaris',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/start.mp4')
      ..initialize().then((_) {
        setState(() {});
        _ctrl.play();
        _ctrl.addListener(() {
          if (_ctrl.value.position >= _ctrl.value.duration) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        });
      }).catchError((e) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _ctrl.value.isInitialized
            ? AspectRatio(
                aspectRatio: _ctrl.value.aspectRatio,
                child: VideoPlayer(_ctrl),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _cardCtrl = TextEditingController();
  String _msg = "";
  bool _unlocked = false;

  Future<String> _deviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return a.id;
    }
    return "unknown";
  }

  Future<void> _activate() async {
    final card = _cardCtrl.text.trim();
    if (card.isEmpty) {
      setState(() => _msg = "请输入卡密");
      return;
    }
    final device = await _deviceId();
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final raw = "$card$device$ts";
    final sign = Hmac(sha256, utf8.encode(SECRET))
        .convert(utf8.encode(raw))
        .toString();
    try {
      final res = await http.post(
        Uri.parse(API),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "card": card,
          "device": device,
          "ts": ts,
          "sign": sign,
        }),
      );
      final data = jsonDecode(res.body);
      if (data["ok"] == true) {
        setState(() {
          _unlocked = true;
          _msg = "激活成功，档位：${data['tier']}";
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("unlocked", true);
      } else {
        setState(() => _msg = "激活失败：${data['detail'] ?? res.body}");
      }
    } catch (e) {
      setState(() => _msg = "网络错误：$e");
    }
  }

  Future<void> _buy() async {
    await launchUrl(
      Uri.parse("https://shop.369fk.lol/liebiao/7C65DDCA24D1EF16"),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _qqGroup() async {
    final key = "920222903";
    final url = "mqqapi://card/show_pslcard?src_type=internal&version=1&uin=$key&card_type=group&source=qrcode";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      await launchUrl(Uri.parse("https://qm.qq.com/cgi-bin/qm/qr?k=$key"));
    }
  }

  Future<void> _qqChat() async {
    final qq = "3959650835";
    final url = "mqqwpa://im/chat?chat_type=wpa&uin=$qq";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      await launchUrl(Uri.parse(
          "https://wpa.qq.com/msgrd?v=3&uin=$qq&site=qq&menu=yes"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Stella Polaris"),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("使用会员密钥以体验更多功能",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                TextField(
                  controller: _cardCtrl,
                  style: const TextStyle(color: Colors.white),
                       decoration: InputDecoration(
                    hintText: "输入激活密钥",
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _buy,
                        child: const Text("购买会员"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _activate,
                        child: const Text("确认密钥"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_msg, style: const TextStyle(color: Colors.amber)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("免费功能",
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _toolBtn("加入QQ群", _qqGroup),
              _toolBtn("联系客服", _qqChat),
              _toolBtn("2048 小游戏", () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const Game2048()));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.apps, color: Color(0xFF4ADE80), size: 20),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class Game2048 extends StatefulWidget {
  const Game2048({super.key});
  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  List<List<int>> grid = List.generate(4, (_) => List.filled(4, 0));
  int score = 0;

  @override
  void initState() {
    super.initState();
    _addTile();
    _addTile();
  }

  void _addTile() {
    final empty = <List<int>>[];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) empty.add([i, j]);
      }
    }
    if (empty.isEmpty) return;
    final pos = empty[DateTime.now().microsecond % empty.length];
    grid[pos[0]][pos[1]] = DateTime.now().millisecond % 10 == 0 ? 4 : 2;
  }

  bool _move(int dir) {
    bool moved = false;
    for (int k = 0; k < 4; k++) {
      final line = <int>[];
      for (int i = 0; i < 4; i++) {
        int r, c;
        if (dir == 0) { r = i; c = k; }
        else if (dir == 1) { r = 3 - i; c = k; }
        else if (dir == 2) { r = k; c = i; }
        else { r = k; c = 3 - i; }
        if (grid[r][c] != 0) line.add(grid[r][c]);
      }
      for (int i = 0; i < line.length - 1; i++) {
        if (line[i] == line[i + 1]) {
          line[i] *= 2;
          score += line[i];
          line.removeAt(i + 1);
        }
      }
      while (line.length < 4) line.add(0);
     for (int i = 0; i < 4; i++) {
        int r, c;
        if (dir == 0) { r = i; c = k; }
        else if (dir == 1) { r = 3 - i; c = k; }
        else if (dir == 2) { r = k; c = i; }
        else { r = k; c = 3 - i; }
        if (grid[r][c] != line[i]) moved = true;
        grid[r][c] = line[i];
      }
    }
    return moved;
  }

  void _swipe(int dir) {
    if (_move(dir)) {
      setState(() {
        _addTile();
      });
    }
  }

  Color _tileColor(int v) {
    const colors = {
      2: Color(0xFFEEE4DA),
      4: Color(0xFFEDE0C8),
      8: Color(0xFFF2B179),
      16: Color(0xFFF59563),
      32: Color(0xFFF67C5F),
      64: Color(0xFFF65E3B),
      128: Color(0xFFEDCF72),
      256: Color(0xFFEDCC61),
      512: Color(0xFFEDC850),
      1024: Color(0xFFEDC53F),
      2048: Color(0xFFEDC22E),
    };
    return colors[v] ?? const Color(0xFF3C3A32);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text("2048  分数：$score"),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: GestureDetector(
        onVerticalDragEnd: (d) {
          if (d.primaryVelocity! < 0) _swipe(0);
          else _swipe(1);
        },
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity! < 0) _swipe(2);
          else _swipe(3);
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 4; i++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int j = 0; j < 4; j++)
                      Container(
                        width: 75,
                        height: 75,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _tileColor(grid[i][j]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          grid[i][j] == 0 ? "" : "${grid[i][j]}",
                          style: TextStyle(
                            fontSize: grid[i][j] > 512 ? 22 : 28,
                            fontWeight: FontWeight.bold,
                            color: grid[i][j] <= 4
                                ? Colors.black87
                                : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              const Text("滑动屏幕移动方块",
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
