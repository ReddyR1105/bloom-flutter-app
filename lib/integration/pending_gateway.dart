import 'bloom_gateway.dart';

/// Explicit production integration blocker, never an in-memory data substitute.
/// Replace the startup injection with Het's real adapter when it is available.
class PendingGateway implements BloomGateway {
  Never _pending() => throw StateError(
    'The SQLite data adapter is awaiting team integration. '
    'No habit data has been loaded or saved.',
  );
  @override
  Future<BloomSnapshot> load() async => _pending();
  @override
  Future<void> createHabit(HabitDraft draft) async => _pending();
  @override
  Future<void> updateHabit(int id, HabitDraft draft) async => _pending();
  @override
  Future<void> deleteHabit(int id) async => _pending();
  @override
  Future<void> start(int habitId, DateTime day) async => _pending();
  @override
  Future<void> updateProgress(int habitId, DateTime day, int progress) async =>
      _pending();
  @override
  Future<void> finish(int habitId, DateTime day) async => _pending();
  @override
  Future<void> reset(int habitId, DateTime day) async => _pending();
  @override
  Future<void> createCheckIn(CheckInDraft draft) async => _pending();
  @override
  Future<void> updateCheckIn(int id, CheckInDraft draft) async => _pending();
  @override
  Future<void> deleteCheckIn(int id) async => _pending();
  @override
  Future<void> saveSettings(SettingsView settings) async => _pending();
  @override
  Future<GoalSuggestionView> suggestGoal(int habitId, DateTime today) async =>
      _pending();
  @override
  Future<void> close() async {}
}
