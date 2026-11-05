import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/common.dart';

class SupermarketApp extends StatefulWidget {
  const SupermarketApp({super.key, required this.state});

  final AppState state;

  @override
  State<SupermarketApp> createState() => _SupermarketAppState();
}

class _SupermarketAppState extends State<SupermarketApp> {
  @override
  void initState() {
    super.initState();
    if (widget.state.booting) unawaited(widget.state.boot());
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'Supermarket',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.booting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.user == null) return const LoginScreen();
    return const HomeShell();
  }
}
