import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pda_rfid_scanner_method_channel.dart';

abstract class PdaRfidScannerPlatform extends PlatformInterface {
  /// Constructs a PdaRfidScannerPlatform.
  PdaRfidScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static PdaRfidScannerPlatform _instance = MethodChannelPdaRfidScanner();

  /// The default instance of [PdaRfidScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelPdaRfidScanner].
  static PdaRfidScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PdaRfidScannerPlatform] when
  /// they register themselves.
  static set instance(PdaRfidScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
