import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import your splash screen widget

void main() => runApp(MyApp());

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
