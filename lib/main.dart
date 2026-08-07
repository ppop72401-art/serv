import 'dart:io';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: NetworkTestScreen()));

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({super.key});
  @override
  State<NetworkTestScreen> createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  String status = "جاهز للاختبار";
  List<String> myIps = [];
  final ipController = TextEditingController();
  ServerSocket? server;

  @override
  void initState() {
    super.initState();
    _fetchIps();
  }

  // استخراج الـ IP الخاص بالجهاز لعرضه للأشخاص الآخرين ليتصلوا به
  Future<void> _fetchIps() async {
    List<String> ips = [];
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) ips.add(addr.address);
      }
    }
    setState(() => myIps = ips);
  }

  // تشغيل السيرفر
  void startServer() async {
    try {
      server = await ServerSocket.bind(InternetAddress.anyIPv4, 8080);
      setState(() => status = "السيرفر يعمل الآن على منفذ 8080\nينتظر الاتصال...");
      
      server!.listen((Socket client) {
        client.listen((data) {
          setState(() => status = "وصلت رسالة من العميل: ${String.fromCharCodes(data)}");
          client.add("تم الاستلام بنجاح من السيرفر!".codeUnits); // إرسال رد للعميل
        });
      });
    } catch (e) {
      setState(() => status = "خطأ في إنشاء السيرفر: $e");
    }
  }

  // الاتصال كسيرفر (العميل)
  void connectToServer() async {
    try {
      setState(() => status = "جاري الاتصال...");
      Socket socket = await Socket.connect(ipController.text.trim(), 8080, timeout: const Duration(seconds: 5));
      socket.add("مرحباً! أنا متصل بشبكتك.".codeUnits);
      
      socket.listen((data) {
        setState(() => status = "رد السيرفر: ${String.fromCharCodes(data)}");
        socket.close();
      });
    } catch (e) {
      setState(() => status = "فشل الاتصال: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار السيرفر المحلي'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.blue.shade50,
              child: Text("الحالة:\n$status", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 40),
            Text("عناويني (IP): ${myIps.join(' | ')}"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: startServer,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('تشغيل كسيرفر (مُنشئ الشبكة)'),
            ),
            const Divider(height: 40),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'أدخل IP السيرفر للاتصال به',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: connectToServer,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('اتصال كعميل'),
            ),
          ],
        ),
      ),
    );
  }
}
