import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  static const MethodChannel _soundChannel =
      MethodChannel('dz.sonelgaz.gparc_mobile/scanner_sound');

  bool found = false;

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (found) return;

    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;

    if (code == null || code.trim().isEmpty) return;

    // Empêche les détections répétées pendant le son de confirmation.
    found = true;

    try {
      await _soundChannel.invokeMethod<void>('playShutter');
    } on PlatformException {
      // La lecture du code reste prioritaire si le son n'est pas disponible.
    } on MissingPluginException {
      // Compatibilité avec les plateformes sans implémentation native.
    }

    if (!mounted) return;
    Navigator.pop(context, code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un code-barres')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleDetection),
          Center(
            child: Container(
              width: 280,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Placez le code-barres dans le cadre. La détection est automatique.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
