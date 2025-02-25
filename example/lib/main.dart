import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pda_rfid_scanner/pda_rfid_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDA RFID Scanner Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ScannerHomePage(),
    );
  }
}

class ScannerHomePage extends StatefulWidget {
  const ScannerHomePage({Key? key}) : super(key: key);

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  String _platformVersion = 'Unknown';
  final List<ScanResult> _scanResults = [];
  ScanType _currentMode = ScanType.unknown;
  bool _isBarcodeActive = false;
  bool _isRfidActive = false;
  bool _autoRestartScan = true;
  StreamSubscription<ScanResult>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
    _setupScanListener();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    // When disposing the widget, turn off all active modules
    PdaRfidScanner.stopBarcodeScan();
    PdaRfidScanner.disableRfid();
    super.dispose();
  }

  // Initialize platform
  Future<void> _initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await PdaRfidScanner.getPlatformVersion() ??
          'Unknown platform version';
    } catch (e) {
      platformVersion = 'Failed to get platform version';
    }

    // Get current device status
    await _updateDeviceStatus();

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  // Update device status
  Future<void> _updateDeviceStatus() async {
    final barcodeActive = await PdaRfidScanner.isScannerActive();
    final rfidActive = await PdaRfidScanner.isRfidActive();
    final currentMode = await PdaRfidScanner.getCurrentMode();

    setState(() {
      _isBarcodeActive = barcodeActive;
      _isRfidActive = rfidActive;
      _currentMode = currentMode;
    });
  }

  // Set up scan listener
  void _setupScanListener() {
    _scanSubscription = PdaRfidScanner.scanStream.listen((ScanResult result) {
      setState(() {
        // Limit list to last 20 results
        _scanResults.insert(0, result);
        if (_scanResults.length > 20) {
          _scanResults.removeLast();
        }
      });
    }, onError: (error) {
      if (kDebugMode) {
        print('Error in scan stream: $error');
      }
    });
  }

  // Start barcode scanner
  Future<void> _startBarcodeScan() async {
    final success = await PdaRfidScanner.startBarcodeScan();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barcode scanner started')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error starting barcode scanner')));
    }

    // Update auto-restart setting
    await PdaRfidScanner.setAutoRestartScan(_autoRestartScan);

    await _updateDeviceStatus();
  }

  // Stop barcode scanner
  Future<void> _stopBarcodeScan() async {
    final success = await PdaRfidScanner.stopBarcodeScan();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barcode scanner stopped')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error stopping barcode scanner')));
    }
    await _updateDeviceStatus();
  }

  // Enable RFID module
  Future<void> _enableRfid() async {
    final success = await PdaRfidScanner.enableRfid();
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('RFID module enabled')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error enabling RFID module')));
    }
    await _updateDeviceStatus();
  }

  // Disable RFID module
  Future<void> _disableRfid() async {
    final success = await PdaRfidScanner.disableRfid();
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('RFID module disabled')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error disabling RFID module')));
    }
    await _updateDeviceStatus();
  }

  // Clear scan results
  void _clearResults() {
    setState(() {
      _scanResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDA RFID Scanner Demo'),
      ),
      body: Column(
        children: [
          // Status panel
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Running on: $_platformVersion'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          'Current mode: ${_currentMode.toString().split('.').last}'),
                    ),
                    Chip(
                      label:
                          Text('Barcode: ${_isBarcodeActive ? "ON" : "OFF"}'),
                      backgroundColor: _isBarcodeActive
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('RFID: ${_isRfidActive ? "ON" : "OFF"}'),
                      backgroundColor:
                          _isRfidActive ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Auto restart after scan'),
                  value: _autoRestartScan,
                  onChanged: (value) {
                    setState(() {
                      _autoRestartScan = value;
                    });
                    if (_isBarcodeActive) {
                      PdaRfidScanner.setAutoRestartScan(value);
                    }
                  },
                  dense: true,
                ),
              ],
            ),
          ),

          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isBarcodeActive
                            ? _stopBarcodeScan
                            : _startBarcodeScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isBarcodeActive
                              ? Colors.redAccent
                              : Colors.greenAccent,
                        ),
                        child: Text(_isBarcodeActive
                            ? 'Stop Barcode'
                            : 'Start Barcode'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRfidActive ? _disableRfid : _enableRfid,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRfidActive
                              ? Colors.redAccent
                              : Colors.greenAccent,
                        ),
                        child: Text(
                            _isRfidActive ? 'Disable RFID' : 'Enable RFID'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _clearResults,
                  child: const Text('Clear Results'),
                ),
              ],
            ),
          ),

          // Results list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue,
                  child: const Text(
                    'Scan Results',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _scanResults.isEmpty
                      ? const Center(child: Text('No scan results yet'))
                      : ListView.builder(
                          itemCount: _scanResults.length,
                          itemBuilder: (context, index) {
                            final result = _scanResults[index];
                            return ListTile(
                              leading: Icon(
                                result.type == ScanType.barcode
                                    ? Icons.qr_code
                                    : Icons.nfc,
                                color: result.type == ScanType.barcode
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                              title: Text(result.data),
                              subtitle: Text(
                                '${result.type.toString().split('.').last} - ${result.timestamp.toString().substring(0, 19)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              dense: true,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
