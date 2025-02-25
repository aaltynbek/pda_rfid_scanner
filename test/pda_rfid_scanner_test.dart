import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pda_rfid_scanner/pda_rfid_scanner.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPdaRfidScannerPlatform with MockPlatformInterfaceMixin {
  Future<String?> getPlatformVersion() => Future.value('42');

  // Mock method calls
  final methodCalls = <String, dynamic>{};
  final List<MethodCall> log = [];

  // Mock scan stream controller
  final StreamController<dynamic> _scanStreamController =
      StreamController<dynamic>.broadcast();

  // For testing scan stream
  void emitScanResult(String data, {bool isRfid = false}) {
    final prefix = isRfid ? 'rfid:' : 'barcode:';
    _scanStreamController.add('$prefix$data');
  }

  // Override methods with recording functionality
  Future<dynamic> invokeMethod(String methodName, [dynamic arguments]) {
    log.add(MethodCall(methodName, arguments));

    switch (methodName) {
      case 'getPlatformVersion':
        return Future.value('42');
      case 'setRfidPowerOn':
      case 'setPowerOn':
        methodCalls['rfidPower'] = true;
        return Future.value('RFID on');
      case 'setRfidPowerOff':
      case 'setPowerOff':
        methodCalls['rfidPower'] = false;
        return Future.value('RFID off');
      case 'startBarcodeScan':
      case 'startScan':
        methodCalls['scannerActive'] = true;
        return Future.value('Scanner started');
      case 'stopBarcodeScan':
        methodCalls['scannerActive'] = false;
        return Future.value('Scanner stopped');
      case 'setAutoRestartScan':
        methodCalls['autoRestart'] = arguments['enable'];
        return Future.value(
            'Auto restart ${arguments['enable'] ? 'enabled' : 'disabled'}');
      case 'isScannerActive':
        return Future.value(methodCalls['scannerActive'] ?? false);
      case 'isRfidActive':
        return Future.value(methodCalls['rfidPower'] ?? false);
      case 'getCurrentMode':
        if (methodCalls['scannerActive'] == true) {
          return Future.value('barcode');
        } else if (methodCalls['rfidPower'] == true) {
          return Future.value('rfid');
        } else {
          return Future.value('unknown');
        }
      default:
        return Future.value(null);
    }
  }

  // For testing the event channel
  Stream<dynamic> getScanStream() {
    return _scanStreamController.stream;
  }

  // Clean up resources
  void dispose() {
    _scanStreamController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  tearDown(() {});

  group('PdaRfidScanner', () {
    test('getPlatformVersion', () async {
      expect(await PdaRfidScanner.getPlatformVersion(), '42');
    });

    test('enableRfid and disableRfid', () async {
      // Test enableRfid
      expect(await PdaRfidScanner.enableRfid(), true);

      // Test isRfidActive after enabling
      expect(await PdaRfidScanner.isRfidActive(), true);

      // Test disableRfid
      expect(await PdaRfidScanner.disableRfid(), true);

      // Test isRfidActive after disabling
      expect(await PdaRfidScanner.isRfidActive(), false);
    });

    test('startBarcodeScan and stopBarcodeScan', () async {
      // Test startBarcodeScan
      expect(await PdaRfidScanner.startBarcodeScan(), true);

      // Test isScannerActive after starting
      expect(await PdaRfidScanner.isScannerActive(), true);

      // Test stopBarcodeScan
      expect(await PdaRfidScanner.stopBarcodeScan(), true);

      // Test isScannerActive after stopping
      expect(await PdaRfidScanner.isScannerActive(), false);
    });

    test('setAutoRestartScan', () async {
      // Test enabling auto restart
      expect(await PdaRfidScanner.setAutoRestartScan(true), true);

      // Test disabling auto restart
      expect(await PdaRfidScanner.setAutoRestartScan(false), true);
    });

    test('getCurrentMode', () async {
      // Initial state
      expect(await PdaRfidScanner.getCurrentMode(), ScanType.unknown);

      // After enabling RFID
      await PdaRfidScanner.enableRfid();
      expect(await PdaRfidScanner.getCurrentMode(), ScanType.rfid);

      // After enabling barcode scanner (should disable RFID)
      await PdaRfidScanner.startBarcodeScan();
      expect(await PdaRfidScanner.getCurrentMode(), ScanType.barcode);

      // After stopping everything
      await PdaRfidScanner.stopBarcodeScan();
      expect(await PdaRfidScanner.getCurrentMode(), ScanType.unknown);
    });

    test('legacy methods compatibility', () async {
      // Test scanStart (equivalent to startBarcodeScan)
      await PdaRfidScanner.scanStart();

      // Test powerOn (equivalent to enableRfid)
      await PdaRfidScanner.powerOn();

      // Test powerOff (equivalent to disableRfid)
      await PdaRfidScanner.powerOff();
    });

    test('scan stream data processing', () async {
      // Create a list to store scan results
      final results = <ScanResult>[];

      // Subscribe to scan stream
      final subscription = PdaRfidScanner.scanStream.listen((result) {
        results.add(result);
      });

      // Emit a barcode scan result

      // Emit an RFID scan result

      // Wait for events to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify results
      expect(results.length, 2);
      expect(results[0].type, ScanType.barcode);
      expect(results[0].data, '1234567890');
      expect(results[1].type, ScanType.rfid);
      expect(results[1].data, '0987654321');

      // Clean up
      await subscription.cancel();
    });
  });

  group('PdaRfidScannerPlatform', () {});

  group('Error handling', () {
    test('handles errors gracefully', () async {
      // Override the platform instance with one that throws errors

      // Methods should return false/default values on error
      expect(await PdaRfidScanner.enableRfid(), false);
      expect(await PdaRfidScanner.disableRfid(), false);
      expect(await PdaRfidScanner.startBarcodeScan(), false);
      expect(await PdaRfidScanner.stopBarcodeScan(), false);
      expect(await PdaRfidScanner.setAutoRestartScan(true), false);
      expect(await PdaRfidScanner.isScannerActive(), false);
      expect(await PdaRfidScanner.isRfidActive(), false);
      expect(await PdaRfidScanner.getCurrentMode(), ScanType.unknown);

      // String-returning methods should include error information
      final powerOnResult = await PdaRfidScanner.powerOn();
      expect(powerOnResult.contains('Error'), true);

      final scanStartResult = await PdaRfidScanner.scanStart();
      expect(scanStartResult.contains('Error'), true);
    });
  });
}

// Mock platform that throws errors for testing error handling
class ErrorThrowingMockPdaRfidScannerPlatform with MockPlatformInterfaceMixin {
  Future<String?> getPlatformVersion() async {
    throw PlatformException(code: 'ERROR', message: 'Test error');
  }

  Future<dynamic> invokeMethod(String methodName, [dynamic arguments]) async {
    throw PlatformException(
        code: 'ERROR', message: 'Test error for $methodName');
  }
}

class Mock {
  // Base class for mocks to satisfy the mixin
}
