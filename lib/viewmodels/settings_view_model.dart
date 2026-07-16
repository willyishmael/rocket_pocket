import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class LoanReminderDefaults {
  final bool enabled;
  final int daysBefore;

  const LoanReminderDefaults({required this.enabled, required this.daysBefore});

  LoanReminderDefaults copyWith({bool? enabled, int? daysBefore}) {
    return LoanReminderDefaults(
      enabled: enabled ?? this.enabled,
      daysBefore: daysBefore ?? this.daysBefore,
    );
  }
}

final loanReminderDefaultsProvider =
    NotifierProvider<LoanReminderDefaultsNotifier, LoanReminderDefaults>(
      LoanReminderDefaultsNotifier.new,
    );

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.system;
  }

  void setMode(ThemeMode mode) {
    state = mode;
    _saveThemeMode(mode);
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeModeKey);
      if (stored == null) {
        return;
      }

      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.system,
      );

      if (state != mode) {
        state = mode;
      }
    } catch (_) {
      // Ignore storage read failures and keep defaults.
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (_) {
      // Keep in-memory setting if preferences are unavailable.
    }
  }
}

class LoanReminderDefaultsNotifier extends Notifier<LoanReminderDefaults> {
  static const _enabledKey = 'loan_reminder_default_enabled';
  static const _daysBeforeKey = 'loan_reminder_default_days_before';

  @override
  LoanReminderDefaults build() {
    _load();
    return const LoanReminderDefaults(enabled: true, daysBefore: 3);
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
    } catch (_) {
      // Keep in-memory value if preferences are unavailable.
    }
  }

  Future<void> setDaysBefore(int daysBefore) async {
    final normalized = daysBefore < 0 ? 0 : daysBefore;
    state = state.copyWith(daysBefore: normalized);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_daysBeforeKey, normalized);
    } catch (_) {
      // Keep in-memory value if preferences are unavailable.
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_enabledKey);
      final daysBefore = prefs.getInt(_daysBeforeKey);
      state = state.copyWith(
        enabled: enabled ?? state.enabled,
        daysBefore: daysBefore ?? state.daysBefore,
      );
    } catch (_) {
      // Ignore storage read failures and keep defaults.
    }
  }
}
