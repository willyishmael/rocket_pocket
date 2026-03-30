import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_pocket/router/navigation_helper.dart';
import 'package:rocket_pocket/viewmodels/settings_view_model.dart';
import 'utils/theme/util.dart';
import 'utils/theme/theme.dart';

void main() {
  NavigationHelper.instance;
  runApp(const ProviderScope(child: RocketPocket()));
}

/// RocketPocket is the main widget of the app.
/// It initializes the app, theme and sets up the router.
class RocketPocket extends ConsumerWidget {
  const RocketPocket({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    TextTheme textTheme = createTextTheme(context, "Poppins", "Poppins");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp.router(
      themeMode: themeMode,
      theme: theme.light(),
      darkTheme: theme.dark(),
      routerConfig: NavigationHelper.router,
    );
  }
}
