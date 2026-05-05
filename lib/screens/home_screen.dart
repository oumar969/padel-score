import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/match_model.dart';
import '../providers/match_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 0, 16),
              title: Text(
                'Padel Score',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.leaderboard_rounded),
                color: Colors.white54,
                onPressed: () => context.push('/stats'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _NewMatchButton(small: true),
              ),
            ],
          ),
          matchesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: _FirebaseError(),
            ),
            data: (matches) {
              if (matches.isEmpty) return SliverFillRemaining(child: _EmptyState());

              final active = matches.where((m) => m.status == MatchStatus.active).toList();
              final finished = matches.where((m) => m.status == MatchStatus.finished).toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (active.isNotEmpty) ...[
                      _SectionLabel(label: 'LIVE', dot: true),
                      ...active.map((m) => _MatchCard(match: m)),
                      const SizedBox(height: 24),
                    ],
                    if (finished.isNotEmpty) ...[
                      _SectionLabel(label: 'AFSLUTTET'),
                      ...finished.map((m) => _MatchCard(match: m)),
                    ],
                  ]),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _NewMatchButton(small: false),
    );
  }
}

class _NewMatchButton extends StatelessWidget {
  final bool small;
  const _NewMatchButton({required this.small});

  @override
  Widget build(BuildContext context) {
    if (small) {
      return IconButton(
        style: IconButton.styleFrom(
          backgroundColor: team1Color.withValues(alpha: 0.15),
          foregroundColor: team1Color,
        ),
        icon: const Icon(Icons.add_rounded),
        onPressed: () => context.push('/new'),
      );
    }
    return FloatingActionButton.extended(
      onPressed: () => context.push('/new'),
      backgroundColor: team1Color,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Ny kamp',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool dot;
  const _SectionLabel({required this.label, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (dot) ...[
            _PulseDot(),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: dot ? team1Color : Colors.white30,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_anim),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: team1Color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final PadelMatch match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = match.status == MatchStatus.active;
    final accentColor = isActive ? team1Color : Colors.white24;

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dividerColor, width: 1),
        ),
        child: Row(
          children: [
            // Colored accent bar
            Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${match.team1Name}  ·  ${match.team2Name}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive && match.winner != null)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              match.winner == 1
                                  ? match.team1Name
                                  : match.team2Name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _ScoreSummary(match: match),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.2), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Slet kamp?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Denne handling kan ikke fortrydes.',
            style: GoogleFonts.inter(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuller',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Slet',
                style: GoogleFonts.inter(
                    color: team2Color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(matchActionsProvider).deleteMatch(match.id);
  }
}

class _ScoreSummary extends StatelessWidget {
  final PadelMatch match;
  const _ScoreSummary({required this.match});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    for (final s in match.completedSets) {
      parts.add('${s.t1}-${s.t2}');
    }
    if (match.status == MatchStatus.active) {
      parts.add('${match.currentSetT1}-${match.currentSetT2}');
    }

    if (parts.isEmpty) {
      return Text('Ikke startet',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white30));
    }

    return Text(
      parts.join('   '),
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: const Icon(Icons.sports_tennis_rounded,
              size: 44, color: Colors.white12),
        ),
        const SizedBox(height: 24),
        Text(
          'Ingen kampe endnu',
          style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white38),
        ),
        const SizedBox(height: 8),
        Text(
          'Tryk på + for at starte en kamp',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white24),
        ),
      ],
    );
  }
}

class _FirebaseError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white12),
        const SizedBox(height: 20),
        Text('Kan ikke forbinde',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white38)),
        const SizedBox(height: 8),
        Text('Kør: flutterfire configure',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white24)),
      ],
    );
  }
}
