import '../data/validation.dart';
import '../integration/bloom_gateway.dart';

class GoalSuggestion {
  const GoalSuggestion({
    required this.completedDays,
    required this.trackedDays,
    required this.windowStart,
    required this.windowEnd,
    required this.daysPerWeek,
    required this.explanation,
  });
  final int completedDays, trackedDays;
  final DateTime windowStart, windowEnd;
  final int? daysPerWeek;
  final String explanation;
}

/// Pure, offline rule. Calendar construction avoids 24-hour arithmetic over DST.
GoalSuggestion calculateGoal({
  required HabitView habit,
  required List<CheckInView> checkIns,
  required DateTime today,
}) {
  validateHabit(
    HabitDraft(
      title: habit.title,
      category: habit.category,
      unit: habit.unit,
      dailyTarget: habit.dailyTarget,
      weeklyTarget: habit.weeklyTarget,
    ),
  );
  final end = localDay(today);
  final start = DateTime(end.year, end.month, end.day - 13);
  if (habit.id <= 0 || localDay(habit.createdAt).isAfter(end)) {
    throw ArgumentError('Invalid habit ID or future creation date.');
  }
  final dates = <String>{};
  final ids = <int>{};
  var tracked = 0;
  var completed = 0;
  for (final entry in checkIns) {
    validateEntry(
      CheckInDraft(
        habitId: entry.habitId,
        day: entry.day,
        progress: entry.progress,
        status: entry.status,
        note: entry.note,
      ),
      habit,
      end,
    );
    if (entry.id <= 0 || !ids.add(entry.id) || !dates.add(dayKey(entry.day))) {
      throw ArgumentError('Duplicate or invalid check-in identity/date.');
    }
    if (localDay(entry.day).isBefore(start)) continue;
    tracked++;
    if (entry.status == CheckInStatus.completed) completed++;
  }
  // Integer arithmetic: half values round upward; clamp AFTER rounding.
  final goal = tracked < 7 ? null : ((completed + 1) ~/ 2).clamp(1, 7);
  return GoalSuggestion(
    completedDays: completed,
    trackedDays: tracked,
    windowStart: start,
    windowEnd: end,
    daysPerWeek: goal,
    explanation: goal == null
        ? 'Not enough history yet: $tracked tracked calendar days; at least 7 are required in the last 14 days.'
        : 'You completed $completed of the last 14 days; try $goal days/week.${completed == 0 ? ' With no completions, this minimum suggestion may be unreliable.' : ''}',
  );
}
