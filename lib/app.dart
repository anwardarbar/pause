import 'package:flutter/cupertino.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/input/input_overlay.dart';

class PauseApp extends StatelessWidget {
  const PauseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Pause',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: const _RootScreen(),
    );
  }
}

/// Root screen wraps HomeScreen with the InputOverlay always present in the
/// widget tree. The overlay animates in/out based on InputOverlayProvider —
/// it is never imperatively pushed as a route.
class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        const InputOverlay(),
      ],
    );
  }
}
