import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rocket_pocket/viewmodels/settings_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThemeModeNotifier persists selected mode', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(themeModeProvider.notifier);
    notifier.setMode(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('ThemeModeNotifier restores persisted mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('LoanReminderDefaultsNotifier persists values', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(loanReminderDefaultsProvider.notifier);
    await notifier.setEnabled(false);
    await notifier.setDaysBefore(7);

    expect(container.read(loanReminderDefaultsProvider).enabled, isFalse);
    expect(container.read(loanReminderDefaultsProvider).daysBefore, 7);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('loan_reminder_default_enabled'), isFalse);
    expect(prefs.getInt('loan_reminder_default_days_before'), 7);
  });

  test('LoanReminderDefaultsNotifier restores persisted values', () async {
    SharedPreferences.setMockInitialValues({
      'loan_reminder_default_enabled': false,
      'loan_reminder_default_days_before': 5,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(loanReminderDefaultsProvider).enabled, isTrue);
    expect(container.read(loanReminderDefaultsProvider).daysBefore, 3);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(loanReminderDefaultsProvider).enabled, isFalse);
    expect(container.read(loanReminderDefaultsProvider).daysBefore, 5);
  });
}
