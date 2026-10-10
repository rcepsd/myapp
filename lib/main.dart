import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
      home: const HomePage(),
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
  int _tabIndex = 0;
  final PageController _bannerCtrl = PageController();
  int _bannerIndex = 0;
  String _timeStr = "--:--";
  Timer? _timer;

  @override
  void initState() {
    super.initState();WidgetsBinding.instance.addPostFrameCallback((_) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text("星盟安全",
          style: TextStyle(color: Colors.white)),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("更新内容",
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 8),
          Text("1. 优化了界面",
              style: TextStyle(color: Colors.white54)),
          SizedBox(height: 4),
          Text("2. 更新社区",
              style: TextStyle(color: Colors.white54)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("确定",
              style: TextStyle(color: Color(0xFF4ADE80))),
        ),
      ],
    ),
  );
});

    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerCtrl.hasClients) {
        final next = (_bannerIndex + 1) % 3;
        _bannerCtrl.animateToPage(next,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut);
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeStr =
          "${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}";
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerCtrl.dispose();
    super.dispose();
  }

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
      setState(() => _msg = "卡密错误");
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
        setState(() => _msg = "卡密错误");
      }
    } catch (e) {
      setState(() => _msg = "卡密错误");
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

  bool _isDay() {
    final h = DateTime.now().hour;
    return h >= 6 && h < 18;
  }

  Widget _bannerItem(String path, {bool showTime = false}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Image.asset(path, fit: BoxFit.cover),
        ),
        if (showTime)
          Center(
            child:IgnorePointer(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF00E5FF),
                    Color(0xFF4ADE80),
                    Color(0xFFFFD700),
                  ],
                ).createShader(bounds),
                child: Text(
                  _timeStr,
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: Color(0xFF00E5FF), blurRadius: 20),
                      Shadow(color: Color(0xFF4ADE80), blurRadius: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeTab(),
      _buildCommunityTab(),
      _buildMineTab(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
  backgroundColor: const Color(0xFF1A1A1A),
  title: ShaderMask(
    shaderCallback: (bounds) => const LinearGradient(
      colors: [
        Color(0xFF00E5FF),
        Color(0xFF4ADE80),
        Color(0xFFFFD700),
      ],
    ).createShader(bounds),
    child: const Text(
      "北极星工作室",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Color(0xFF00E5FF), blurRadius: 12),
          Shadow(color: Color(0xFF4ADE80), blurRadius: 20),
        ],
      ),
    ),
  ),
),

      body: pages[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFF4ADE80),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "社区"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              PageView(
                controller: _bannerCtrl,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
                children: [
                  _bannerItem(_isDay() ? "assets/day.png" : "assets/night.png",
                      showTime: true),
                  _bannerItem(_isDay() ? "assets/night.png" : "assets/day.png",
                      showTime: true),
                  _bannerItem("assets/poster.jpg", showTime: false),
                ],
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      width: _bannerIndex == i ? 16 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _bannerIndex == i
                            ? const Color(0xFF4ADE80)
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
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
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("免费功能",
              style: TextStyle(color: Colors.white54, fontSize: 16)),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
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
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCommunityTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF00E5FF),
                    Color(0xFF4ADE80),
                    Color(0xFFFFD700),
                  ],
                ).createShader(bounds),
                child: const Text(
                  "星盟安全社区",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0xFF00E5FF), blurRadius: 12),
                      Shadow(color: Color(0xFF4ADE80), blurRadius: 20),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AuthPage()));
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF4ADE80), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF4ADE80), blurRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.person,
                      color: Color(0xFF4ADE80), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("社区列表",
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WallFeedPage()));
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF4ADE80)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.forum,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("社区",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("发帖 · 评论 · 关注",
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMineTab() {
    return const Center(
      child: Text("我的", style: TextStyle(color: Colors.white54)),
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

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("社区账号"),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _userCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "用户名",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "密码",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text("登录"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text("注册"),
                  ),
                ),
              ],
            ),
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

class WallFeedPage extends StatefulWidget {
  const WallFeedPage({super.key});
  @override
  State<WallFeedPage> createState() => _WallFeedPageState();
}

class _WallFeedPageState extends State<WallFeedPage> {
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  String _nickname = "游客";
  String _avatar = "";
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadMessages();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nickname = prefs.getString("nickname") ?? "游客";
      _avatar = prefs.getString("avatar") ?? "";
    });
  }

  Future<void> _loadMessages() async {
    try {
      final res = await http
          .get(Uri.parse("http://47.114.49.46/api/chat/messages"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _messages = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {}
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await http.post(
        Uri.parse("http://47.114.49.46/api/chat/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nickname": _nickname,
          "content": text,
          "avatar": _avatar,
        }),
      );
      _msgCtrl.clear();
      await _loadMessages();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("星盟安全社区"),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isMe = m["nickname"] == _nickname;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isMe)
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF1A1A1A),
                          child: Text(
                            (m["nickname"] ?? "?").toString()[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(m["nickname"] ?? "",
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                m["content"] ?? "",
                                style: TextStyle(
                                  color: isMe ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isMe)
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF4ADE80),
                          child: Text(
                            _nickname[0],
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "说点什么...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send, color: Color(0xFF4ADE80)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
