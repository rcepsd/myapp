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
      title: 'MyApp',
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
      appBar: AppBar(title: const Text("MyApp")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_unlocked) ...[
              TextField(
                controller: _cardCtrl,
                decoration: const InputDecoration(
                  labelText: "输入卡密",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _activate,
                child: const Text("激活"),
              ),
            ] else
              const Text("已解锁高级功能", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text(_msg),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _buy, child: const Text("购买卡密")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _qqGroup, child: const Text("加入QQ群")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _qqChat, child: const Text("联系客服")),
          ],
        ),
      ),
    );
  }
}
