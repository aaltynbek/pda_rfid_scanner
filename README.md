# pda_rfid_scanner

A Flutter plugin project for RFID scan on Blovedream PDA.

## Getting Started

- Power on Plugin

```dart
PdaRfidScanner.powerOn();
```

- Power off Plugin

```dart
PdaRfidScanner.powerOff();
```

- Using stream to handle scanned information

```dart
StreamSubscription? _streamSubscription;
String rfid = '';

@override
void initState() {
    _streamSubscription =
        PdaRfidScanner.channel.receiveBroadcastStream().listen(
      (dynamic event) {
        debugPrint('Received event: $event');
        setState(() {
          rfid = event;
        });
      },
      onError: (dynamic error) {
        debugPrint('Received error: ${error.message}');
      },
      cancelOnError: true,
    );
    super.initState();
}
```