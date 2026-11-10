import 'package:flutter/widgets.dart';

void main() => runApp(const CordCardApp());

class CordCardApp extends StatelessWidget {
  const CordCardApp({super.key});

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: const Color(0xFF142537),
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    ),
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF142537),
        child: SafeArea(
          child: Center(
            child: Semantics(
              label: 'Cord Card is an early development preview',
              child: Text(
                'Cord Card\nInventory coming soon',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
