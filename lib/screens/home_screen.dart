import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/match_model.dart';
import '../models/player_stats.dart';
import '../providers/match_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _tab,
        children: const [_MatchesTab(), _StatsTab()],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: surfaceColor,
        indicatorColor: team1Color.withValues(alpha: 0.15),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.sports_tennis_rounded),
            label: 'Kampe',
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_rounded),
            label: 'Statistik',
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/new'),
              backgroundColor: team1Color,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text('Ny kamp',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            )
          : null,
    );
  }
}

// ── Kampe tab ─────────────────────────────────────────────────────────────────

class _MatchesTab extends ConsumerWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          expandedHeight: 120,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(24, 0, 0, 16),
            title: Text('Padel Score',
                style: GoogleFonts.inter(
                    fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: team1Color.withValues(alpha: 0.15),
                  foregroundColor: team1Color,
                ),
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.push('/new'),
              ),
            ),
          ],
        ),
        matchesAsync.when(
          loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator())),
          error: (_, __) => SliverFillRemaining(child: _FirebaseError()),
          data: (matches) {
            if (matches.isEmpty) {
              return SliverFillRemaining(child: _EmptyState());
            }
            final active =
                matches.where((m) => m.status == MatchStatus.active).toList();
            final finished =
                matches.where((m) => m.status == MatchStatus.finished).toList();

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
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
    );
  }
}

// ── Statistik tab ─────────────────────────────────────────────────────────────

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(playerStatsProvider);
    final matchesAsync = ref.watch(matchesProvider);
    final totalMatches = matchesAsync.valueOrNull?.length ?? 0;
    final finished =
        matchesAsync.valueOrNull?.where((m) => m.status == MatchStatus.finished).length ?? 0;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          expandedHeight: 120,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(24, 0, 0, 16),
            title: Text('Statistik',
                style: GoogleFonts.inter(
                    fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
        if (stats.isEmpty)
          SliverFillRemaining(child: _EmptyStats())
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                _SummaryChip(label: 'Spillere', value: '${stats.length}'),
                const SizedBox(width: 10),
                _SummaryChip(label: 'Kampe', value: '$totalMatches'),
                const SizedBox(width: 10),
                _SummaryChip(label: 'Afsluttet', value: '$finished'),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(child: _TableHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _PlayerCard(stats: stats[i], rank: i + 1),
                childCount: stats.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Delte widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool dot;
  const _SectionLabel({required this.label, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        if (dot) ...[_PulseDot(), const SizedBox(width: 8)],
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: dot ? team1Color : Colors.white30,
            )),
      ]),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: Container(width: 7, height: 7,
          decoration: const BoxDecoration(color: team1Color, shape: BoxShape.circle)),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final PadelMatch match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = match.status == MatchStatus.active;

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dividerColor),
        ),
        child: Row(children: [
          Container(
            width: 4, height: 80,
            decoration: BoxDecoration(
              color: isActive ? team1Color : Colors.white24,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      '${match.team1Name}  ·  ${match.team2Name}',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isActive && match.winner != null)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        match.winner == 1 ? match.team1Name : match.team2Name,
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white54),
                      ),
                    ),
                ]),
                const SizedBox(height: 6),
                _ScoreSummary(match: match),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 22),
          ),
        ]),
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
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Annuller', style: GoogleFonts.inter(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('Slet', style: GoogleFonts.inter(
                  color: team2Color, fontWeight: FontWeight.w700))),
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
    final parts = [
      ...match.completedSets.map((s) => '${s.t1}-${s.t2}'),
      if (match.status == MatchStatus.active)
        '${match.currentSetT1}-${match.currentSetT2}',
    ];
    if (parts.isEmpty) {
      return Text('Ikke startet',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white30));
    }
    return Text(parts.join('   '),
        style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: Colors.white38, letterSpacing: 0.5));
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dividerColor),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.inter(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
        ]),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        SizedBox(width: 32,
            child: Text('#', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white24, letterSpacing: 1))),
        const Expanded(child: SizedBox()),
        for (final label in ['S', 'T', 'Win%'])
          SizedBox(width: 44, child: Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white24, letterSpacing: 1),
          )),
      ]),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final PlayerStats stats;
  final int rank;
  const _PlayerCard({required this.stats, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTop = rank <= 3;
    final rankColor = rank == 1
        ? goldColor
        : rank == 2 ? const Color(0xFFB0BEC5)
        : rank == 3 ? const Color(0xFFBF8970)
        : Colors.white24;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? rankColor.withValues(alpha: 0.2) : dividerColor,
          width: isTop ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        SizedBox(width: 32,
            child: Text('$rank', style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w800, color: rankColor))),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stats.name, style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            if (stats.bestPartner != null)
              Text('Bedst med ${stats.bestPartner}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white30)),
          ]),
        ),
        SizedBox(width: 44, child: Text('${stats.wins}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: team1Color))),
        SizedBox(width: 44, child: Text('${stats.losses}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: team2Color))),
        SizedBox(width: 44, child: Text(stats.winRatePct,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white60))),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 100, height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: const Icon(Icons.sports_tennis_rounded, size: 44, color: Colors.white12),
      ),
      const SizedBox(height: 24),
      Text('Ingen kampe endnu', style: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white38)),
      const SizedBox(height: 8),
      Text('Tryk på + for at starte en kamp',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white24)),
    ]);
  }
}

class _EmptyStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 90, height: 90,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: const Icon(Icons.leaderboard_rounded, size: 40, color: Colors.white12),
      ),
      const SizedBox(height: 20),
      Text('Ingen statistik endnu', style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white30)),
      const SizedBox(height: 8),
      Text('Spil og afslut kampe for at se statistik',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.2))),
    ]);
  }
}

class _FirebaseError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white12),
      const SizedBox(height: 20),
      Text('Kan ikke forbinde', style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white38)),
    ]);
  }
}
