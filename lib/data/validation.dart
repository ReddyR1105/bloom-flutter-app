import '../integration/bloom_gateway.dart';

DateTime localDay(DateTime value) {
  if (value.isUtc || value.year < 1 || value.year > 9999) {
    throw ArgumentError('Use a local calendar date in years 1–9999.');
  }
  return DateTime(value.year, value.month, value.day);
}

String dayKey(DateTime value) {
  final day = localDay(value);
  return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

DateTime parseDay(String value) {
  final result = DateTime.tryParse(value);
  if (result == null || dayKey(result) != value) {
    throw FormatException('Invalid saved calendar date: $value');
  }
  return result;
}

void validateHabit(HabitDraft value) {
  if (value.title.trim().isEmpty ||
      value.category.trim().isEmpty ||
      value.unit.trim().isEmpty) {
    throw ArgumentError('Title, category and unit must not be empty.');
  }
  if (value.dailyTarget < 1 ||
      value.dailyTarget > 100000 ||
      value.weeklyTarget < 1 ||
      value.weeklyTarget > 7) {
    throw ArgumentError('Daily target must be 1–100000 and weekly target 1–7.');
  }
}

void validateEntry(CheckInDraft value, HabitView habit, DateTime today) {
  final day = localDay(value.day);
  if (value.habitId != habit.id ||
      day.isBefore(localDay(habit.createdAt)) ||
      day.isAfter(localDay(today))) {
    throw ArgumentError(
      'Check-in must belong to this habit and be between its creation date and today.',
    );
  }
  if (value.progress < 0 ||
      value.progress > habit.dailyTarget ||
      (value.status == CheckInStatus.started && value.progress != 0) ||
      (value.status == CheckInStatus.inProgress && value.progress == 0) ||
      (value.status == CheckInStatus.completed &&
          value.progress != habit.dailyTarget)) {
    throw ArgumentError(
      'Progress must be 0..target; started requires zero, in_progress positive progress, completed the target.',
    );
  }
}
