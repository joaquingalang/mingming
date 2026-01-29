import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mingming/game/mingming_game.dart';
import 'package:mingming/pages/home_page.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

Future<void> _initializeRevenueCat() async {
  // Platform-specific API keys
  String apiKey;
  if (Platform.isIOS) {
    apiKey = 'test_AFSBlZHpoYLbQwCXRyHhVCkoWoy';
  } else if (Platform.isAndroid) {
    apiKey = 'test_AFSBlZHpoYLbQwCXRyHhVCkoWoy';
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(PurchasesConfiguration(apiKey));
}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();


  await _initializeRevenueCat();

  runApp(Mingming());
}

class Mingming extends StatelessWidget {
  const Mingming({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mingming',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

// Old template page removed. HomePage is now the entry screen.
