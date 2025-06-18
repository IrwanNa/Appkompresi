// main.dart
// import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_v1/screen/splash_screen.dart';
import 'package:flutter_app_v1/screen/upload_screen.dart';
import 'package:flutter_app_v1/screen/result_screen.dart';

void main() {
  runApp(WansApp());
}

class WansApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WansApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/upload': (context) => UploadPage(),
        '/result': (context) => ResultPage(),
      },
    );
  }
}
