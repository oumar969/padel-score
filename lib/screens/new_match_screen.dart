import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/match_settings.dart';
import '../providers/match_provider.dart';

class NewMatchScreen extends ConsumerStatefulWidget {
  const NewMatchScreen({super.key});

  @override
  ConsumerState<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends ConsumerState<NewMatchScreen> {
  String _format = '1v1';
  MatchSettings _settings = const MatchSettings();
  int _initialServer = 1;
  bool _loading = false;

  final _t1 = List.generate(4, (i) => TextEditingController(text: 'Spiller ${i + 1}'));
  final _t2 = List.generate(4, (i) => TextEditingController(text: 'Spiller ${i + 5}'));

  int get _count => _format == '1v1' ? 1 : 2;

  @override
  void dispose() {
    for (final c in [..._t1, ..._t2]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _start() async {
    final t1 = _t1.take(_count).map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final t2 = _t2.take(_count).map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (t1.isEmpty || t2.isEmpty) return;
    setState(() => _loading = true);
    try {
      final id = await ref.read(matchActionsProvider).createMatch(
            _format, t1, t2, _settings, _initialServer);
      if (mounted) context.replace('/match/$id');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fejl: $e'),
          backgroundColor: team2Color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ny kamp',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format
              _label('FORMAT'),
              const SizedBox(height: 10),
              Row(children: [
                _FormatChip(label: '1v1', selected: _format == '1v1',
                    onTap: () => setState(() => _format = '1v1')),
                const SizedBox(width: 10),
                _FormatChip(label: '2v2', selected: _format == '2v2',
                    onTap: () => setState(() => _format = '2v2')),
              ]),

              const SizedBox(height: 28),

              // Teams
              _teamSection('HOLD 1', team1Color, _t1, _count),
              const SizedBox(height: 16),
              Center(child: Text('VS', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w800,
                letterSpacing: 3, color: Colors.white24))),
              const SizedBox(height: 16),
              _teamSection('HOLD 2', team2Color, _t2, _count),

              const SizedBox(height: 32),

              // Settings
              _label('TILVALG'),
              const SizedBox(height: 12),
              _SettingsCard(
                settings: _settings,
                initialServer: _initialServer,
                onChanged: (s) => setState(() => _settings = s),
                onServerChanged: (v) => setState(() => _initialServer = v),
              ),

              const SizedBox(height: 32),

              _loading
                  ? const Center(child: CircularProgressIndicator(color: team1Color))
                  : ElevatedButton(onPressed: _start, child: const Text('Start kamp')),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w700,
      letterSpacing: 2, color: Colors.white30));

  Widget _teamSection(String label, Color color, List<TextEditingController> ctrls, int count) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 2, color: color.withValues(alpha: 0.8))),
      ]),
      const SizedBox(height: 10),
      ...List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _PlayerInput(controller: ctrls[i], color: color, index: i + 1),
      )),
    ]);
  }
}

// ── Settings card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final MatchSettings settings;
  final int initialServer;
  final ValueChanged<MatchSettings> onChanged;
  final ValueChanged<int> onServerChanged;

  const _SettingsCard({
    required this.settings,
    required this.initialServer,
    required this.onChanged,
    required this.onServerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      child: Column(children: [
        _toggle(
          icon: '🔥',
          title: 'Varm op timer',
          subtitle: '5 min nedtælling inden kamp',
          value: settings.warmup,
          onChanged: (v) => onChanged(settings.copyWith(warmup: v)),
        ),
        _divider(),
        _toggle(
          icon: '🎾',
          title: 'Serveindikator',
          subtitle: 'Viser hvems tur det er at serve',
          value: settings.serveIndicator,
          onChanged: (v) => onChanged(settings.copyWith(serveIndicator: v)),
          extra: settings.serveIndicator
              ? _ServerPicker(value: initialServer, onChanged: onServerChanged)
              : null,
        ),
        _divider(),
        _toggle(
          icon: '⏱',
          title: 'Timeout knap',
          subtitle: '60 sek pause med nedtælling',
          value: settings.timeout,
          onChanged: (v) => onChanged(settings.copyWith(timeout: v)),
        ),
        _divider(),
        _toggle(
          icon: '🔔',
          title: 'Boldbytte påmindelse',
          subtitle: 'Notifikation efter 9 spil',
          value: settings.ballReminder,
          onChanged: (v) => onChanged(settings.copyWith(ballReminder: v)),
        ),
        _divider(),
        _toggle(
          icon: '↔️',
          title: 'Side-skift påmindelse',
          subtitle: 'Banner når holdene skal skifte side',
          value: settings.sideSwitch,
          onChanged: (v) => onChanged(settings.copyWith(sideSwitch: v)),
        ),
        _divider(),
        _toggle(
          icon: '💬',
          title: 'Live kommentarer',
          subtitle: 'Tilskuere kan skrive kommentarer',
          value: settings.liveComments,
          onChanged: (v) => onChanged(settings.copyWith(liveComments: v)),
          isLast: true,
        ),
      ]),
    );
  }

  Widget _toggle({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? extra,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 8, isLast ? 14 : 14),
      child: Column(children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            Text(subtitle, style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white38)),
          ])),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: team1Color,
            trackColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? team1Color.withValues(alpha: 0.3)
                    : Colors.white12),
          ),
        ]),
        if (extra != null) ...[const SizedBox(height: 10), extra],
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFF2A2A40));
}

class _ServerPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _ServerPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('Starter serve:', style: GoogleFonts.inter(
          fontSize: 12, color: Colors.white54)),
      const SizedBox(width: 12),
      _chip(1, team1Color, 'Hold 1'),
      const SizedBox(width: 8),
      _chip(2, team2Color, 'Hold 2'),
    ]);
  }

  Widget _chip(int team, Color color, String label) {
    final selected = value == team;
    return GestureDetector(
      onTap: () => onChanged(team),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? color : Colors.white24),
        ),
        child: Text(label, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? color : Colors.white38)),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _FormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FormatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? team1Color : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? team1Color : dividerColor),
        ),
        child: Text(label, style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: selected ? Colors.white : Colors.white38)),
      ),
    );
  }
}

class _PlayerInput extends StatelessWidget {
  final TextEditingController controller;
  final Color color;
  final int index;
  const _PlayerInput({required this.controller, required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14),
          child: Text('$index', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.5))),
        ),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
