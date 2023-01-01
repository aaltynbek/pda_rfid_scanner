import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pda_rfid_scanner/pda_rfid_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _streamSubscription;
  String _platformMessage = '';
  String status = 'off';

  void _enableEventReceiver() {
    _streamSubscription =
        PdaRfidScanner.channel.receiveBroadcastStream().listen(
      (dynamic event) {
        debugPrint('Received event: $event');
        setState(() {
          _platformMessage = event;
        });
      },
      onError: (dynamic error) {
        debugPrint('Received error: ${error.message}');
      },
      cancelOnError: true,
    );
  }

  void _disableEventReceiver() {
    if (_streamSubscription != null) {
      _streamSubscription!.cancel();
      _streamSubscription = null;
    }
  }

  @override
  void initState() {
    _enableEventReceiver();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _disableEventReceiver();
  }

  powerOn() async {
    final value = await PdaRfidScanner.powerOn();
    setState(() {
      status = value;
    });
  }

  powerOff() async {
    final value = await PdaRfidScanner.powerOff();
    setState(() {
      status = value;
    });
  }

  startScan() async {
    final value = await PdaRfidScanner.scanStart();
    setState(() {
      status = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Plugin status: $status'),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    powerOn();
                  },
                  child: const Text('power on'),
                ),
                ElevatedButton(
                  onPressed: () {
                    powerOn();
                  },
                  child: const Text('power off'),
                ),
                ElevatedButton(
                  onPressed: () {
                    startScan();
                  },
                  child: const Text('start'),
                ),
                Text('Running on: \n $_platformMessage'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
