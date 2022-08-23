import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pda_rfid_scanner_platform_interface.dart';

/// An implementation of [PdaRfidScannerPlatform] that uses method channels.
class MethodChannelPdaRfidScanner extends PdaRfidScannerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pda_rfid_scanner');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
