import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/counter/counter_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fancy Counter App',
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.black45,
        textTheme: GoogleFonts.tekoTextTheme(),
      ),
      home: const CounterPage(),
    );
  }
}
