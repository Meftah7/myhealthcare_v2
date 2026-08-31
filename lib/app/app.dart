/// Root widget: `MaterialApp.router` with the DESIGN.md theme and go_router
/// (tasks P0-05, P0-06).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/theme.dart';

class MyHealthCareApp extends StatefulWidget {
  const MyHealthCareApp({super.key});

  @override
  State<MyHealthCareApp> createState() => _MyHealthCareAppState();
}

class _MyHealthCareAppState extends State<MyHealthCareApp> {
  final GoRouter _router = buildAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MyHealth Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
