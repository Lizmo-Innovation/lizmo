import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'screens/rent_roll_screen.dart';

void main() => runApp(const LizmoApp());

class LizmoApp extends StatelessWidget {
  const LizmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lizmo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: LizmoColors.teal900,
          primary: LizmoColors.teal900,
          surface: LizmoColors.canvas,
        ),
        scaffoldBackgroundColor: LizmoColors.canvas,
        useMaterial3: true,
      ),
      home: const RentRollScreen(),
    );
  }
}
