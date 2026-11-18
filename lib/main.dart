import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'database.dart';

const purple = Color(0xFF7657D6);
const palePurple = Color(0xFFEEE9FF);
const appBackground = Color(0xFFF9F8FC);

void main() => runApp(const RuniverseApp());

class RuniverseApp extends StatelessWidget {
  const RuniverseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Runiverse',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF4F1FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: const RuniverseHome(),
  );
}

class RuniverseHome extends StatefulWidget {
  const RuniverseHome({super.key});
  @override
  State<RuniverseHome> createState() => _RuniverseHomeState();
}

class _RuniverseHomeState extends State<RuniverseHome> {
  final _db = AppDatabase.instance;
  int _tab = 0;
  bool _loading = true, _gameEnabled = true, _spendKm = false;
  List<RunEntry> _runs = [];
  List<Reward> _rewards = [];
  double get _totalKm => _runs.fold(0, (sum, run) => sum + run.distanceKm);
  int get _totalMinutes =>
      _runs.fold(0, (sum, run) => sum + run.durationMinutes);
  double get _spentKm =>
      _rewards.where((r) => r.redeemed).fold(0, (sum, r) => sum + r.costKm);
  double get _availableKm =>
      (_totalKm - (_spendKm ? _spentKm : 0)).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final values = await Future.wait([
      _db.getRuns(),
      _db.getRewards(),
      _db.getSetting('game_enabled', fallback: true),
      _db.getSetting('spend_km', fallback: false),
    ]);
    if (!mounted) return;
    setState(() {
      _runs = values[0] as List<RunEntry>;
      _rewards = values[1] as List<Reward>;
      _gameEnabled = values[2] as bool;
      _spendKm = values[3] as bool;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      Dashboard(
        runs: _runs,
        totalKm: _totalKm,
        totalMinutes: _totalMinutes,
        gameEnabled: _gameEnabled,
      ),
      RunsPage(
        runs: _runs,
        onDelete: (id) async {
          await _db.deleteRun(id);
          await _refresh();
        },
      ),
      RewardsPage(
        rewards: _rewards,
        availableKm: _availableKm,
        gameEnabled: _gameEnabled,
        onRedeem: (id) async {
          await _db.redeemReward(id);
          await _refresh();
        },
        onDelete: (id) async {
          await _db.deleteReward(id);
          await _refresh();
        },
      ),
      SettingsPage(
        gameEnabled: _gameEnabled,
        spendKm: _spendKm,
        onGameChanged: (v) async {
          await _db.setSetting('game_enabled', v);
          await _refresh();
        },
        onSpendChanged: (v) async {
          await _db.setSetting('spend_km', v);
          await _refresh();
        },
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBackground,
        title: const Text(
          'runiverse',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: palePurple,
              child: Text(
                '${_totalKm.round()}',
                style: const TextStyle(
                  color: purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pages[_tab],
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddRun,
              icon: const Icon(Icons.add),
              label: const Text('Add run'),
            )
          : _tab == 2 && _gameEnabled
          ? FloatingActionButton.extended(
              onPressed: _showAddReward,
              icon: const Icon(Icons.add),
              label: const Text('Add reward'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (v) => setState(() => _tab = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Runs',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }

  Future<void> _showAddRun() async {
    final distance = TextEditingController(),
        duration = TextEditingController(),
        note = TextEditingController();
    DateTime date = DateTime.now();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add a run',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: distance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Distance (km)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Time (minutes)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDate: date,
                  );
                  if (picked != null) setSheetState(() => date = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(DateFormat('MMM d, yyyy').format(date)),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save run'),
              ),
            ],
          ),
        ),
      ),
    );
    final km = double.tryParse(distance.text.replaceAll(',', '.')),
        minutes = int.tryParse(duration.text);
    if (saved == true &&
        km != null &&
        km > 0 &&
        minutes != null &&
        minutes > 0) {
      await _db.addRun(
        RunEntry(
          date: date,
          distanceKm: km,
          durationMinutes: minutes,
          note: note.text.trim(),
        ),
      );
      await _refresh();
    }
  }

  Future<void> _showAddReward() async {
    final title = TextEditingController(), cost = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New reward',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'What do you want?'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Required distance (km)',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create reward'),
            ),
          ],
        ),
      ),
    );
    final km = double.tryParse(cost.text.replaceAll(',', '.'));
    if (saved == true && title.text.trim().isNotEmpty && km != null && km > 0) {
      await _db.addReward(Reward(title: title.text.trim(), costKm: km));
      await _refresh();
    }
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.runs,
    required this.totalKm,
    required this.totalMinutes,
    required this.gameEnabled,
  });
  final List<RunEntry> runs;
  final double totalKm;
  final int totalMinutes;
  final bool gameEnabled;
  static const ranks = [
    ('Starter', 0.0),
    ('Runner', 25.0),
    ('Pacer', 75.0),
    ('Athlete', 150.0),
    ('Marathoner', 300.0),
    ('Legend', 500.0),
  ];
  @override
  Widget build(BuildContext context) {
    var index = ranks.lastIndexWhere((r) => totalKm >= r.$2);
    if (index < 0) index = 0;
    final current = ranks[index],
        next = index < ranks.length - 1 ? ranks[index + 1] : current;
    final progress = next.$2 == current.$2
        ? 1.0
        : ((totalKm - current.$2) / (next.$2 - current.$2)).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        const Text(
          'Keep moving.',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const Text(
          'Every kilometer counts.',
          style: TextStyle(color: Color(0xFF817B8A), fontSize: 16),
        ),
        const SizedBox(height: 22),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL DISTANCE',
                style: TextStyle(
                  color: purple,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${totalKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Stat(
                      icon: Icons.timer_outlined,
                      value: '${totalMinutes ~/ 60}h ${totalMinutes % 60}m',
                      label: 'Time',
                    ),
                  ),
                  Expanded(
                    child: Stat(
                      icon: Icons.route_outlined,
                      value: '${runs.length}',
                      label: 'Runs',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (gameEnabled) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT RANK',
                          style: TextStyle(
                            color: Color(0xFF817B8A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          current.$1,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: palePurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor: palePurple,
                ),
                const SizedBox(height: 8),
                Text(
                  index == ranks.length - 1
                      ? 'Top rank reached'
                      : '${(next.$2 - totalKm).clamp(0, double.infinity).toStringAsFixed(1)} km to ${next.$1}',
                  style: const TextStyle(color: Color(0xFF817B8A)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const Text(
          'Recent runs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (runs.isEmpty)
          const EmptyCard(
            icon: Icons.directions_run,
            text: 'Your first run will appear here.',
          )
        else
          ...runs.take(3).map((r) => RunTile(run: r)),
      ],
    );
  }
}

class RunsPage extends StatelessWidget {
  const RunsPage({super.key, required this.runs, required this.onDelete});
  final List<RunEntry> runs;
  final Future<void> Function(int) onDelete;
  @override
  Widget build(BuildContext context) => runs.isEmpty
      ? const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: EmptyCard(
              icon: Icons.directions_run,
              text: 'No runs yet. Tap “Add run” to begin.',
            ),
          ),
        )
      : ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            const Text(
              'Run history',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ...runs.map(
              (run) => Dismissible(
                key: ValueKey(run.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => onDelete(run.id!),
                child: RunTile(run: run),
              ),
            ),
          ],
        );
}

class RewardsPage extends StatelessWidget {
  const RewardsPage({
    super.key,
    required this.rewards,
    required this.availableKm,
    required this.gameEnabled,
    required this.onRedeem,
    required this.onDelete,
  });
  final List<Reward> rewards;
  final double availableKm;
  final bool gameEnabled;
  final Future<void> Function(int) onRedeem, onDelete;
  @override
  Widget build(BuildContext context) {
    if (!gameEnabled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: EmptyCard(
            icon: Icons.sports_score,
            text: 'The game system is turned off. Enable it in Settings.',
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        const Text(
          'Your rewards',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        Text(
          '${availableKm.toStringAsFixed(1)} km available',
          style: const TextStyle(
            color: purple,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        if (rewards.isEmpty)
          const EmptyCard(
            icon: Icons.card_giftcard,
            text: 'Create something worth running for.',
          ),
        ...rewards.map((reward) {
          final unlocked = availableKm >= reward.costKm;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: reward.redeemed
                          ? const Color(0xFFE4F6ED)
                          : palePurple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      reward.redeemed ? Icons.check : Icons.card_giftcard,
                      color: reward.redeemed ? const Color(0xFF3E9C70) : purple,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${reward.costKm.toStringAsFixed(1)} km',
                          style: const TextStyle(color: Color(0xFF817B8A)),
                        ),
                      ],
                    ),
                  ),
                  if (!reward.redeemed)
                    IconButton.filledTonal(
                      onPressed: unlocked ? () => onRedeem(reward.id!) : null,
                      tooltip: unlocked ? 'Claim reward' : 'Keep running',
                      icon: Icon(unlocked ? Icons.redeem : Icons.lock_outline),
                    )
                  else
                    IconButton(
                      onPressed: () => onDelete(reward.id!),
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.gameEnabled,
    required this.spendKm,
    required this.onGameChanged,
    required this.onSpendChanged,
  });
  final bool gameEnabled, spendKm;
  final ValueChanged<bool> onGameChanged, onSpendChanged;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
    children: [
      const Text(
        'Settings',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 18),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              value: gameEnabled,
              onChanged: onGameChanged,
              title: const Text(
                'Game system',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Ranks and personal rewards'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              value: spendKm,
              onChanged: gameEnabled ? onSpendChanged : null,
              title: const Text(
                'Spend kilometers',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Claimed rewards reduce your balance'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const AppCard(
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: purple),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Private by design',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'All runs, rewards and settings stay on this device.',
                    style: TextStyle(color: Color(0xFF817B8A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class RunTile extends StatelessWidget {
  const RunTile({super.key, required this.run});
  final RunEntry run;
  @override
  Widget build(BuildContext context) {
    final m = run.pace.floor(), s = ((run.pace - m) * 60).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: palePurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.directions_run, color: purple),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(run.date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (run.note.isNotEmpty)
                    Text(
                      run.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF817B8A)),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${run.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  '$m:${s.toString().padLeft(2, '0')} /km',
                  style: const TextStyle(color: Color(0xFF817B8A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class Stat extends StatelessWidget {
  const Stat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: purple),
      const SizedBox(width: 9),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Color(0xFF817B8A))),
        ],
      ),
    ],
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Icon(icon, size: 38, color: purple),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF817B8A), fontSize: 16),
        ),
      ],
    ),
  );
}
