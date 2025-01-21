import 'package:connected_fridge/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


import '/screens/home_screen.dart';
import '/screens/login_screen.dart';
import '/screens/signup_screen.dart';
import '/screens/welcome.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner OpenFoodFacts',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
       initialRoute: HomeScreen.id,
      routes: {
        HomeScreen.id: (context) => HomeScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        SignUpScreen.id: (context) => SignUpScreen(),
        WelcomeScreen.id: (context) => WelcomeScreen(),
        ScanScreen.id:(context) => ScanScreen(onBarcodeScanned: (barcode) {
          // Handle the scanned barcode here
        }),
      },
    );
  }
}

