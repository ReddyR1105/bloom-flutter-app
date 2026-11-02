/// Rohan-owned UI boundary. Het's adapter maps his actual models to these values.
/// This file deliberately contains no persistence or helper calculation.
library;

enum CheckInStatus { started, inProgress, completed }

class HabitView {
  const HabitView({
    required this.id,
    required this.title,
    required this.category,
    required this.unit,
    required this.dailyTarget,
    required this.weeklyTarget,
    required this.createdAt,
    this.archived = false,
  });
  final int id;
  final String title, category, unit;
  final int dailyTarget, weeklyTarget;
  final DateTime createdAt;
  final bool archived;
}

class HabitDraft {
  const HabitDraft({
    required this.title,
    required this.category,
    required this.unit,
    required this.dailyTarget,
    required this.weeklyTarget,
  });
  final String title, category, unit;
  final int dailyTarget, weeklyTarget;
}

class CheckInView {
  const CheckInView({
    required this.id,
    required this.habitId,
    required this.day,
    required this.progress,
    required this.status,
    this.note = '',
  });
  final int id, habitId, progress;
  final DateTime day;
  final CheckInStatus status;
  final String note;
}

class CheckInDraft {
  const CheckInDraft({
    required this.habitId,
    required this.day,
    required this.progress,
    required this.status,
    required this.note,
  });
  final int habitId, progress;
  final DateTime day;
  final CheckInStatus status;
  final String note;
}

class SettingsView {
  const SettingsView({
    this.defaultTarget = 20,
    this.weekStartsMonday = true,
    this.reducedMotion = false,
  });
  final int defaultTarget;
  final bool weekStartsMonday, reducedMotion;
}

class BloomSnapshot {
  const BloomSnapshot({
    required this.habits,
    required this.checkIns,
    required this.settings,
  });
  final List<HabitView> habits;
  final List<CheckInView> checkIns;
  final SettingsView settings;
}

class GoalSuggestionView {
  const GoalSuggestionView({
    required this.explanation,
    this.daysPerWeek,
    this.baselineDaysPerWeek = 3,
  });
  final String explanation;
  final int? daysPerWeek;
  final int baselineDaysPerWeek;
}

/// Every mutation completes only when persisted. Failures throw an actionable
/// exception; UI refreshes from load() after success. Dates are local calendar
/// dates. Enforce validation, unique habit/date and progress bounds below UI.
abstract interface class BloomGateway {
  Future<BloomSnapshot> load();
  Future<void> createHabit(HabitDraft draft);
  Future<void> updateHabit(int id, HabitDraft draft);
  Future<void> deleteHabit(int id);
  Future<void> start(int habitId, DateTime day);
  Future<void> updateProgress(int habitId, DateTime day, int progress);
  Future<void> finish(int habitId, DateTime day);
  Future<void> reset(int habitId, DateTime day);
  Future<void> createCheckIn(CheckInDraft draft);
  Future<void> updateCheckIn(int id, CheckInDraft draft);
  Future<void> deleteCheckIn(int id);
  Future<void> saveSettings(SettingsView settings);
  Future<GoalSuggestionView> suggestGoal(int habitId, DateTime today);
  Future<void> close();
}
