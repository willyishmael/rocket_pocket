import 'package:flutter/material.dart';
import 'package:rocket_pocket/router/navigation_helper.dart';
import 'util.dart';
import 'theme.dart';

void main() {
  NavigationHelper.instance;
  runApp(const RocketPocket());
}

/// RocketPocket is the main widget of the app.
/// It initializes the app, theme and sets up the router.
class RocketPocket extends StatelessWidget {
  const RocketPocket({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Poppins", "Poppins");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp.router(
      theme: brightness == Brightness.dark ? theme.dark() : theme.light(),
      routerConfig: NavigationHelper.router,
    );
  }
}
