import 'package:flutter_test/flutter_test.dart';
import 'package:pda_rfid_scanner/pda_rfid_scanner.dart';
import 'package:pda_rfid_scanner/pda_rfid_scanner_platform_interface.dart';
import 'package:pda_rfid_scanner/pda_rfid_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPdaRfidScannerPlatform
    with MockPlatformInterfaceMixin
    implements PdaRfidScannerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PdaRfidScannerPlatform initialPlatform =
      PdaRfidScannerPlatform.instance;

  test('$MethodChannelPdaRfidScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPdaRfidScanner>());
  });

  test('getPlatformVersion', () async {
    PdaRfidScanner pdaRfidScannerPlugin = PdaRfidScanner();
    MockPdaRfidScannerPlatform fakePlatform = MockPdaRfidScannerPlatform();
    PdaRfidScannerPlatform.instance = fakePlatform;

    // expect(await pdaRfidScannerPlugin.getPlatformVersion(), '42');
  });
}
