import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import your splash screen widget
import 'dart:io';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOVE TRAFFIC APP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(), // Use SplashScreen as the initial screen
    );
  }
}
