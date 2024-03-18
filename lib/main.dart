import 'package:flutter/material.dart';
import './TableListPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => TableListPage(),
      },
    );

  }
}
