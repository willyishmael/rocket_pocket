import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// This function returns a MaterialPage with the given child and state.
/// It is used to create a page for the GoRouter.
/// The [child] is the widget that will be displayed on the page.
/// The [state] is the GoRouterState that contains information about the current route.
Page getPage({required Widget child, required GoRouterState state}) {
  return MaterialPage(child: child, key: state.pageKey);
}
