# PDA RFID Scanner

A comprehensive Flutter plugin for industrial PDA devices supporting both barcode scanning and RFID tag reading. The plugin is optimized for Blovedream PDA devices but may work with other similar hardware.

[![Pub Version](https://img.shields.io/pub/v/pda_rfid_scanner.svg)](https://pub.dev/packages/pda_rfid_scanner)

## Features

- Barcode scanning using the physical scan button on the device
- Low-frequency RFID card scanning
- Real-time scan result streaming
- Configurable auto-restart for continuous scanning
- Simple API with Flutter-friendly interfaces
- Comprehensive error handling
- Support for both modern API and legacy methods

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pda_rfid_scanner: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Basic Usage

### Initialize

Import the package:

```dart
import 'package:pda_rfid_scanner/pda_rfid_scanner.dart';
```

### Barcode Scanning

```dart
// Start barcode scanner
await PdaRfidScanner.startBarcodeScan();

// Enable auto-restart (for continuous scanning)
await PdaRfidScanner.setAutoRestartScan(true);

// Stop barcode scanner when done
await PdaRfidScanner.stopBarcodeScan();
```

### RFID Scanning

```dart
// Enable RFID module
await PdaRfidScanner.enableRfid();

// Disable RFID module when done
await PdaRfidScanner.disableRfid();
```

### Receiving Scan Results

```dart
StreamSubscription? _scanSubscription;

@override
void initState() {
  super.initState();
  
  // Listen for scan results
  _scanSubscription = PdaRfidScanner.scanStream.listen(
    (ScanResult result) {
      print('Scan type: ${result.type}');
      print('Scanned data: ${result.data}');
      print('Timestamp: ${result.timestamp}');
      
      // Handle the scan result
      if (result.type == ScanType.barcode) {
        // Process barcode
      } else if (result.type == ScanType.rfid) {
        // Process RFID tag
      }
    },
    onError: (error) {
      print('Error receiving scan: $error');
    }
  );
}

@override
void dispose() {
  // Don't forget to cancel subscription when done
  _scanSubscription?.cancel();
  
  // And turn off scanners to save battery
  PdaRfidScanner.stopBarcodeScan();
  PdaRfidScanner.disableRfid();
  
  super.dispose();
}
```

## Advanced Usage

### Check Device Status

```dart
// Check if barcode scanner is active
bool isScannerActive = await PdaRfidScanner.isScannerActive();

// Check if RFID module is active
bool isRfidActive = await PdaRfidScanner.isRfidActive();

// Get current scanning mode
ScanType currentMode = await PdaRfidScanner.getCurrentMode();
```

### Legacy API Support

For compatibility with older code:

```dart
// Start barcode scanner (legacy method)
await PdaRfidScanner.scanStart();

// Enable RFID (legacy method)
await PdaRfidScanner.powerOn();

// Disable RFID (legacy method)
await PdaRfidScanner.powerOff();
```

### Legacy Stream Access

If you need direct access to the stream:

```dart
PdaRfidScanner.channel.receiveBroadcastStream().listen(
  (dynamic event) {
    print('Received event: $event');
    // Process raw event data
  },
  onError: (dynamic error) {
    print('Received error: ${error.message}');
  }
);
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:pda_rfid_scanner/pda_rfid_scanner.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScannerPage(),
    );
  }
}

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String _lastScan = 'No scan yet';
  ScanType _lastScanType = ScanType.unknown;
  StreamSubscription? _scanSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Start barcode scanner on startup
    PdaRfidScanner.startBarcodeScan();
    PdaRfidScanner.setAutoRestartScan(true);
    
    // Listen for scan results
    _scanSubscription = PdaRfidScanner.scanStream.listen(
      (ScanResult result) {
        setState(() {
          _lastScan = result.data;
          _lastScanType = result.type;
        });
      },
    );
  }
  
  @override
  void dispose() {
    _scanSubscription?.cancel();
    PdaRfidScanner.stopBarcodeScan();
    PdaRfidScanner.disableRfid();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scanner Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Last scan: $_lastScan'),
            Text('Type: ${_lastScanType.toString().split('.').last}'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => PdaRfidScanner.startBarcodeScan(),
                  child: Text('Start Barcode'),
                ),
                ElevatedButton(
                  onPressed: () => PdaRfidScanner.enableRfid(),
                  child: Text('Start RFID'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## Notes & Best Practices

1. **Mode Switching**: Barcode scanning and RFID reading cannot be active simultaneously. Enabling one will automatically disable the other.

2. **Button Activation**: You must call `startBarcodeScan()` to activate the physical scan button on the device.

3. **Auto-Restart**: Enable auto-restart with `setAutoRestartScan(true)` if you need to scan multiple items consecutively. Otherwise, the scanner will stop after each scan.

4. **Resource Management**: Always:
   - Cancel stream subscriptions in `dispose()`
   - Disable scanners/RFID when not in use to save battery

5. **Error Handling**: The plugin includes built-in error handling, but it's recommended to implement your own error processing in the `onError` callback of the stream subscription.

## Troubleshooting

- **Scan button not working**: Ensure you've called `startBarcodeScan()` before using the physical button.

- **Scanner stops after one scan**: Make sure auto-restart is enabled with `setAutoRestartScan(true)`.

- **RFID not detecting cards**: Verify that you're using the correct type of RFID cards (low-frequency) and that the RFID module is enabled with `enableRfid()`.

- **App crashes when exiting**: Ensure you're properly disposing resources in the `dispose()` method.

## Platform Support

- Android: ✅ Supported
- iOS: ❌ Not supported (PDA devices typically run Android)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.