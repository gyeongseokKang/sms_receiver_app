import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readsms/readsms.dart';
import 'package:sms_api_app/uitls/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = Readsms();
  String sms = 'no sms received';
  String sender = 'no sms received';
  String time = 'no sms received';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('new sms received: $sms'),
              Text('new sms Sender: $sender'),
              Text('new sms time: $time'),
              // 버튼 생성
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _plugin.dispose();
  }

  Future<bool> getPermission() async {
    if (await Permission.sms.status == PermissionStatus.granted) {
      return true;
    } else {
      if (await Permission.sms.request() == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getPermission().then((value) {
      if (value) {
        _plugin.read();
        _plugin.smsStream.listen((event) async {
          try {
            await parseSms(event);

            setState(() {
              sms = event.body;
              sender = event.sender;
              time = event.timeReceived.toString();
            });
          } catch (e) {}
        });
      }
    });
  }

  Future<void> parseSms(SMS event) async {
    String messageType = event.body.split("\n")[0]; // [Web발신]
    String remittanceTime = event.body.split("\n")[1]; //[KB]11/22 21:58

    String recipientAccount = event.body.split("\n")[2]; //477402**058
    String remitterName = event.body.split("\n")[3]; //강경석
    String remittanceType = event.body.split("\n")[4].contains("입금")
        ? "DEPOSIT"
        : "WITHDRAWAL"; //전자금융입금
    int remittanceAmount =
        int.parse(event.body.split("\n")[5].replaceAll(",", "")); // 10
    int remittanceBalance = int.parse(event.body
        .split("\n")[6]
        .replaceAll("잔액", "")
        .replaceAll(",", "")); // 잔액8,314

    final res = await dio.post(
      'https://handy.com/v1/accounts',
      data: {
        "account": recipientAccount,
        "amount": remittanceAmount,
        "balance": remittanceBalance,
        "name": remitterName,
        "type": remittanceType
      },
    );
  }
}
