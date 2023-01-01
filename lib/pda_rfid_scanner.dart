import 'package:flutter/services.dart';
export 'package:flutter/services.dart';

class PdaRfidScanner {
  const PdaRfidScanner();

  static const platform = MethodChannel('pda_rfid_scanner');
  static const EventChannel channel = EventChannel('pda_rfid_scanner/stream');

  static Future<String> powerOn() async {
    return await platform.invokeMethod('setPowerOn');
  }

  static Future<String> powerOff() async {
    return await platform.invokeMethod('setPowerOff');
  }

  static Future<String> scanStart() async {
    return await platform.invokeMethod('startScan');
  }
}
