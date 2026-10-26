import 'dart:async';
import 'package:flutter/material.dart';
import '../integration/bloom_gateway.dart';
import 'editors.dart';
import 'habit_detail.dart';
import 'widgets.dart';

class BloomApp extends StatefulWidget {
  const BloomApp({super.key, required this.gateway});
  final BloomGateway gateway;
  @override
  State<BloomApp> createState() => _BloomAppState();
}

class _BloomAppState extends State<BloomApp> {
  @override
  void dispose() {
    unawaited(widget.gateway.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bloom',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFAF8F2),
      colorScheme: ColorScheme.fromSeed(
        seedColor: forest,
        brightness: Brightness.light,
        surface: const Color(0xFFFAF8F2),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFAF8F2)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: forest,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    home: BloomHome(gateway: widget.gateway),
  );
}

class BloomHome extends StatefulWidget {
  const BloomHome({super.key, required this.gateway});
  final BloomGateway gateway;
  @override
  State<BloomHome> createState() => _BloomHomeState();
}

class _BloomHomeState extends State<BloomHome> {
  BloomSnapshot? _data;
  String? _error;
  int _tab = 0;
  int? _historyHabit;
  String? _category;
  bool _loading = true;
  bool _saving = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await widget.gateway.load();
      if (!mounted || generation != _generation) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = readableError(error);
        _loading = false;
      });
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(
      bloomRoute<void>(context, page, _data?.settings.reducedMotion ?? false),
    );
    if (mounted) await _reload();
  }

  Future<void> _settings(SettingsView settings) async {
    setState(() => _saving = true);
    try {
      await widget.gateway.saveSettings(settings);
      if (mounted) await _reload();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final titles = ['Today', 'Your habits', 'History & insights', 'Settings'];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'bloom.',
          style: TextStyle(
            color: forest,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _reload,
            tooltip: 'Refresh saved data',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ContentColumn(
              children: [
                const Icon(Icons.cloud_off, size: 40, color: forest),
                const Text('Your habits could not be loaded', style: heading),
                Text(_error!),
                FilledButton(
                  onPressed: _reload,
                  child: const Text('Try again'),
                ),
              ],
            )
          : data == null
          ? const SizedBox.shrink()
          : MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations:
                    MediaQuery.of(context).disableAnimations ||
                    data.settings.reducedMotion,
              ),
              child: RefreshIndicator(
                onRefresh: _reload,
                child: ContentColumn(
                  children: [
                    Text(titles[_tab], style: heading),
                    if (_tab == 0) ..._today(data),
                    if (_tab == 1) ..._habits(data),
                    if (_tab == 2) ..._history(data),
                    if (_tab == 3) ..._preferences(data),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Insights',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }

  List<Widget> _today(BloomSnapshot data) {
    final today = localDay(DateTime.now());
    final habits = data.habits.where((h) => !h.archived).toList();
    final todayEntries = data.checkIns
        .where((c) => sameDay(c.day, today))
        .toList();
    final complete = habits
        .where(
          (h) => todayEntries.any(
            (c) => c.habitId == h.id && c.status == CheckInStatus.completed,
          ),
        )
        .length;
    final totalComplete = data.checkIns
        .where((c) => c.status == CheckInStatus.completed)
        .length;
    final categories = habits.map((h) => h.category).toSet().toList()..sort();
    final category = categories.contains(_category) ? _category : null;
    return [
      Text('Small steps for ${dateLabel(today)}.'),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A little progress goes a long way.', style: subheading),
            const SizedBox(height: 16),
            Garden(completed: totalComplete),
            const SizedBox(height: 12),
            Text('$complete of ${habits.length} habits completed today'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: habits.isEmpty ? 0 : complete / habits.length,
              semanticsLabel:
                  'Today’s completed habits: $complete of ${habits.length}',
            ),
          ],
        ),
      ),
      if (categories.isNotEmpty)
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('category-$category'),
          initialValue: category,
          decoration: const InputDecoration(labelText: 'Filter by category'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All categories')),
            ...categories.map(
              (c) => DropdownMenuItem(value: c, child: Text(c)),
            ),
          ],
          onChanged: (value) => setState(() => _category = value),
        ),
      ..._habitCards(
        data,
        habits
            .where((h) => category == null || h.category == category)
            .toList(),
      ),
      FilledButton.icon(
        onPressed: () => _open(
          HabitEditor(
            gateway: widget.gateway,
            defaultTarget: data.settings.defaultTarget,
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New habit'),
      ),
    ];
  }

  List<Widget> _habits(BloomSnapshot data) => [
    const Text('Give one small goal a place to grow.'),
    ..._habitCards(data, data.habits.where((h) => !h.archived).toList()),
    FilledButton.icon(
      onPressed: () => _open(
        HabitEditor(
          gateway: widget.gateway,
          defaultTarget: data.settings.defaultTarget,
        ),
      ),
      icon: const Icon(Icons.add),
      label: const Text('New habit'),
    ),
  ];

  List<Widget> _habitCards(BloomSnapshot data, List<HabitView> habits) =>
      habits.isEmpty
      ? [
          const SurfaceCard(
            child: Text(
              'No habits here yet. Create a small, measurable goal to get started.',
            ),
          ),
        ]
      : habits.map((h) {
          final today = data.checkIns.where(
            (c) => c.habitId == h.id && sameDay(c.day, DateTime.now()),
          );
          final entry = today.isEmpty ? null : today.first;
          return HabitCard(
            habit: h,
            checkIn: entry,
            onTap: () =>
                _open(HabitDetail(gateway: widget.gateway, habitId: h.id)),
          );
        }).toList();

  List<Widget> _history(BloomSnapshot data) {
    final today = localDay(DateTime.now());
    final startDay = data.settings.weekStartsMonday
        ? DateTime.monday
        : DateTime.sunday;
    final start = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - startDay + 7) % 7,
    );
    final selected = data.habits.any((h) => h.id == _historyHabit)
        ? _historyHabit
        : null;
    final relevantHabits = data.habits
        .where((h) => !h.archived && (selected == null || h.id == selected))
        .toList();
    final entries =
        data.checkIns
            .where((c) => selected == null || c.habitId == selected)
            .toList()
          ..sort((a, b) => b.day.compareTo(a.day));
    final activeIds = relevantHabits.map((h) => h.id).toSet();
    final weekCompletions = entries
        .where(
          (c) =>
              activeIds.contains(c.habitId) &&
              !localDay(c.day).isBefore(start) &&
              !localDay(c.day).isAfter(today) &&
              c.status == CheckInStatus.completed,
        )
        .length;
    var opportunities = 0;
    for (
      var day = start;
      !day.isAfter(today);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      opportunities += relevantHabits
          .where((h) => !localDay(h.createdAt).isAfter(day))
          .length;
    }
    return [
      DropdownButtonFormField<int>(
        isExpanded: true,
        key: ValueKey('habit-filter-$selected'),
        initialValue: selected,
        decoration: const InputDecoration(labelText: 'Filter by habit'),
        items: [
          const DropdownMenuItem(value: null, child: Text('All habits')),
          ...data.habits.map(
            (h) => DropdownMenuItem(value: h.id, child: Text(h.title)),
          ),
        ],
        onChanged: (value) => setState(() => _historyHabit = value),
      ),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This week · ${dateLabel(start)}–${dateLabel(today)}',
              style: subheading,
            ),
            Text('$weekCompletions completed check-ins'),
            Text(
              opportunities == 0
                  ? 'Completion rate: no eligible days yet'
                  : 'Completion rate: ${(100 * weekCompletions / opportunities).round()}%',
            ),
            const Text(
              'Rate uses one opportunity per active habit per elapsed day, '
              'starting on its creation date. Archived habits are excluded from this summary.',
            ),
          ],
        ),
      ),
      OutlinedButton.icon(
        onPressed: data.habits.isEmpty
            ? null
            : () =>
                  _open(CheckInEditor(gateway: widget.gateway, snapshot: data)),
        icon: const Icon(Icons.edit_calendar),
        label: const Text('Add a past check-in'),
      ),
      if (entries.isEmpty)
        const SurfaceCard(
          child: Text(
            'No saved check-ins. Start a habit or add an accurate past entry.',
          ),
        ),
      ...entries.map((c) {
        final matching = data.habits.where((h) => h.id == c.habitId);
        final habit = matching.isEmpty ? null : matching.first;
        return SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habit?.title ?? 'Unavailable habit', style: subheading),
              Text('${dateLabel(c.day)} · ${statusLabel(c.status)}'),
              Text('${c.progress} ${habit?.unit ?? "units"}'),
              if (c.note.isNotEmpty) Text(c.note),
              TextButton(
                onPressed: habit == null
                    ? null
                    : () => _open(
                        CheckInEditor(
                          gateway: widget.gateway,
                          snapshot: data,
                          existing: c,
                        ),
                      ),
                child: const Text('Correct or delete check-in'),
              ),
            ],
          ),
        );
      }),
    ];
  }

  List<Widget> _preferences(BloomSnapshot data) {
    final settings = data.settings;
    return [
      const Text('Your space, your pace. All habit data stays on this device.'),
      if (_saving) const LinearProgressIndicator(),
      SurfaceCard(
        child: Column(
          children: [
            Text(
              'Default daily target: ${settings.defaultTarget}',
              style: subheading,
            ),
            const Text(
              'New habits use this value in their selected measurement unit.',
            ),
            Wrap(
              spacing: 12,
              children: [
                IconButton(
                  tooltip: 'Decrease default target',
                  onPressed: _saving || settings.defaultTarget <= 1
                      ? null
                      : () => _settings(
                          SettingsView(
                            defaultTarget: settings.defaultTarget - 1,
                            weekStartsMonday: settings.weekStartsMonday,
                            reducedMotion: settings.reducedMotion,
                          ),
                        ),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  tooltip: 'Increase default target',
                  onPressed: _saving || settings.defaultTarget >= 100000
                      ? null
                      : () => _settings(
                          SettingsView(
                            defaultTarget: settings.defaultTarget + 1,
                            weekStartsMonday: settings.weekStartsMonday,
                            reducedMotion: settings.reducedMotion,
                          ),
                        ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
      SwitchListTile(
        title: const Text('Start week on Monday'),
        subtitle: Text(settings.weekStartsMonday ? 'Monday' : 'Sunday'),
        value: settings.weekStartsMonday,
        onChanged: _saving
            ? null
            : (value) => _settings(
                SettingsView(
                  defaultTarget: settings.defaultTarget,
                  weekStartsMonday: value,
                  reducedMotion: settings.reducedMotion,
                ),
              ),
      ),
      SwitchListTile(
        title: const Text('Reduced motion'),
        subtitle: const Text(
          'Keep the garden calm and respect device motion preferences.',
        ),
        value: settings.reducedMotion,
        onChanged: _saving
            ? null
            : (value) => _settings(
                SettingsView(
                  defaultTarget: settings.defaultTarget,
                  weekStartsMonday: settings.weekStartsMonday,
                  reducedMotion: value,
                ),
              ),
      ),
      const Text(
        'No account, cloud sync, or reminders requiring online services. '
        'Deleting the app may remove local records; no cloud backup is provided.',
      ),
    ];
  }
}
