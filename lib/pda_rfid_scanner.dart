import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Types of scan data
enum ScanType { barcode, rfid, unknown }

/// Scan result data
class ScanResult {
  final String data;
  final ScanType type;
  final DateTime timestamp;

  ScanResult({
    required this.data,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '$type: $data';
}

/// Main class for working with PDA scanner and RFID
class PdaRfidScanner {
  static const MethodChannel _channel = MethodChannel('pda_rfid_scanner');
  static const EventChannel _eventChannel =
      EventChannel('pda_rfid_scanner/stream');

  static Stream<ScanResult>? _scanStream;

  /// Get a stream of scan results
  static Stream<ScanResult> get scanStream {
    _scanStream ??= _eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is String) {
        if (event.startsWith('barcode:')) {
          return ScanResult(
            data: event.substring(8).trim(),
            type: ScanType.barcode,
          );
        } else if (event.startsWith('rfid:')) {
          return ScanResult(
            data: event.substring(5).trim(),
            type: ScanType.rfid,
          );
        } else {
          // For backward compatibility - assume barcode if no prefix
          return ScanResult(
            data: event.trim(),
            type: ScanType.barcode,
          );
        }
      }
      return ScanResult(data: event.toString(), type: ScanType.unknown);
    });

    return _scanStream!;
  }

  /// Get platform version
  static Future<String?> getPlatformVersion() async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Enable RFID module (turns off barcode scanner if active)
  static Future<bool> enableRfid() async {
    try {
      final String result = await _channel.invokeMethod('setRfidPowerOn');
      return result.contains('on');
    } catch (e) {
      if (kDebugMode) {
        print('Error enabling RFID: $e');
      }
      return false;
    }
  }

  /// Disable RFID module
  static Future<bool> disableRfid() async {
    try {
      final String result = await _channel.invokeMethod('setRfidPowerOff');
      return result.contains('off');
    } catch (e) {
      if (kDebugMode) {
        print('Error disabling RFID: $e');
      }
      return false;
    }
  }

  /// Start barcode scanning (turns off RFID if active)
  static Future<bool> startBarcodeScan() async {
    try {
      final String result = await _channel.invokeMethod('startBarcodeScan');
      return result.contains('started') || result.contains('already on');
    } catch (e) {
      if (kDebugMode) {
        print('Error starting barcode scanner: $e');
      }
      return false;
    }
  }

  /// Stop barcode scanning
  static Future<bool> stopBarcodeScan() async {
    try {
      final String result = await _channel.invokeMethod('stopBarcodeScan');
      return result.contains('stopped') || result.contains('already off');
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping barcode scanner: $e');
      }
      return false;
    }
  }

  /// Set auto-restart option for barcode scanning
  /// When enabled, scanner will automatically restart after each scan
  static Future<bool> setAutoRestartScan(bool enable) async {
    try {
      final String result =
          await _channel.invokeMethod('setAutoRestartScan', {'enable': enable});
      return result.contains('enabled') || result.contains('disabled');
    } catch (e) {
      if (kDebugMode) {
        print('Error setting auto restart: $e');
      }
      return false;
    }
  }

  /// Check if barcode scanner is active
  static Future<bool> isScannerActive() async {
    try {
      return await _channel.invokeMethod('isScannerActive') ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking scanner status: $e');
      }
      return false;
    }
  }

  /// Check if RFID module is active
  static Future<bool> isRfidActive() async {
    try {
      return await _channel.invokeMethod('isRfidActive') ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking RFID status: $e');
      }
      return false;
    }
  }

  /// Get current operation mode (barcode/rfid/unknown)
  static Future<ScanType> getCurrentMode() async {
    try {
      final String mode =
          await _channel.invokeMethod('getCurrentMode') ?? 'unknown';
      switch (mode) {
        case 'barcode':
          return ScanType.barcode;
        case 'rfid':
          return ScanType.rfid;
        default:
          return ScanType.unknown;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current mode: $e');
      }
      return ScanType.unknown;
    }
  }

  // Backward compatibility methods

  /// For backward compatibility with previous library version
  /// Start scanning (barcode scanner)
  static Future<String> scanStart() async {
    try {
      return await _channel.invokeMethod('startScan');
    } catch (e) {
      if (kDebugMode) {
        print('Error in scanStart: $e');
      }
      return 'Error: $e';
    }
  }

  /// For backward compatibility with previous library version
  /// Power on (RFID module)
  static Future<String> powerOn() async {
    try {
      return await _channel.invokeMethod('setPowerOn');
    } catch (e) {
      if (kDebugMode) {
        print('Error in powerOn: $e');
      }
      return 'Error: $e';
    }
  }

  /// For backward compatibility with previous library version
  /// Power off (RFID module)
  static Future<String> powerOff() async {
    try {
      return await _channel.invokeMethod('setPowerOff');
    } catch (e) {
      if (kDebugMode) {
        print('Error in powerOff: $e');
      }
      return 'Error: $e';
    }
  }
}
