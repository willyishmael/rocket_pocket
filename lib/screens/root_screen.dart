import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootScreen extends StatefulWidget {
  final StatefulNavigationShell child;

  const RootScreen({super.key, required this.child});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Root Screen'));
  }
}
