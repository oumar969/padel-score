import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../providers/match_provider.dart';

class NewMatchScreen extends ConsumerStatefulWidget {
  const NewMatchScreen({super.key});

  @override
  ConsumerState<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends ConsumerState<NewMatchScreen> {
  String _format = '2v2';
  bool _loading = false;

  // Max 4 players per team (for 4v4)
  final _t1 = List.generate(4, (i) => TextEditingController(text: 'Spiller ${i + 1}'));
  final _t2 = List.generate(4, (i) => TextEditingController(text: 'Spiller ${i + 5}'));

  int get _count => _format == '2v2' ? 2 : 4;

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
      final id = await ref.read(matchActionsProvider).createMatch(_format, t1, t2);
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
        title: Text('Ny kamp', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format selector
              _FormatSelector(
                selected: _format,
                onChanged: (f) => setState(() => _format = f),
              ),

              const SizedBox(height: 28),

              // Team 1
              _teamSection('HOLD 1', team1Color, _t1, _count),
              const SizedBox(height: 20),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text('VS',
                      style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        letterSpacing: 3, color: Colors.white24,
                      )),
                ),
              ),

              const SizedBox(height: 20),

              // Team 2
              _teamSection('HOLD 2', team2Color, _t2, _count),

              const SizedBox(height: 36),

              _loading
                  ? const Center(child: CircularProgressIndicator(color: team1Color))
                  : ElevatedButton(
                      onPressed: _start,
                      child: const Text('Start kamp'),
                    ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamSection(String label, Color color, List<TextEditingController> ctrls, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 2, color: color.withValues(alpha: 0.8),
          )),
        ]),
        const SizedBox(height: 10),
        ...List.generate(count, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PlayerInput(controller: ctrls[i], color: color, index: i + 1),
        )),
      ],
    );
  }
}

class _FormatSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FormatSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FORMAT', style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 2, color: Colors.white30,
        )),
        const SizedBox(height: 10),
        Row(children: [
          _FormatChip(label: '2v2', selected: selected == '2v2', onTap: () => onChanged('2v2')),
          const SizedBox(width: 10),
          _FormatChip(label: '4v4', selected: selected == '4v4', onTap: () => onChanged('4v4')),
        ]),
      ],
    );
  }
}

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
          border: Border.all(
            color: selected ? team1Color : dividerColor,
            width: selected ? 0 : 1,
          ),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w800,
          color: selected ? Colors.white : Colors.white38,
        )),
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
          child: Text('$index',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.5),
              )),
        ),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
