import 'dart:ui';
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
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: const [_MatchesTab(), _StatsTab()],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A).withValues(alpha: 0.72),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              indicatorColor: team1Color.withValues(alpha: 0.15),
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.sports_tennis_rounded),
                  label: 'Kampe',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_rounded),
                  label: 'Statistik',
                ),
              ],
            ),
          ),
        ),
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
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
    final t1Won = match.winner == 1;
    final t2Won = match.winner == 2;

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? team1Color.withValues(alpha: 0.35)
                : dividerColor,
          ),
          boxShadow: isActive
              ? [BoxShadow(
                  color: team1Color.withValues(alpha: 0.10),
                  blurRadius: 24, spreadRadius: 0, offset: const Offset(0, 4))]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(children: [
            // ── Team row ──────────────────────────────────────
            IntrinsicHeight(
              child: Row(children: [
                // Team 1
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 10, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          team1Color.withValues(alpha: t1Won ? 0.18 : 0.08),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(match.team1Name,
                            style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: t1Won ? Colors.white : Colors.white70,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (t1Won) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: team1Color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Vinder 🏆',
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: team1Color)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Score center
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: _SetScore(match: match),
                ),
                // Team 2
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 18, 16, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          team2Color.withValues(alpha: t2Won ? 0.18 : 0.08),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(match.team2Name,
                            style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: t2Won ? Colors.white : Colors.white70,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end),
                        if (t2Won) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: team2Color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Vinder 🏆',
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: team2Color)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ]),
            ),
            // ── Bottom bar ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: dividerColor, width: 0.8)),
              ),
              child: Row(children: [
                if (isActive) ...[
                  _PulseDot(),
                  const SizedBox(width: 6),
                  Text('LIVE', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: team1Color, letterSpacing: 1.5,
                  )),
                ] else
                  Text('AFSLUTTET', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: Colors.white24, letterSpacing: 1.2,
                  )),
                const Spacer(),
                if (!isActive)
                  GestureDetector(
                    onTap: () => context.push('/match/${match.id}/analysis'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: team1Color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.bar_chart_rounded, size: 14, color: team1Color),
                        const SizedBox(width: 5),
                        Text('Analyse', style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700, color: team1Color,
                        )),
                      ]),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.2), size: 20),
              ]),
            ),
          ]),
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

class _SetScore extends StatelessWidget {
  final PadelMatch match;
  const _SetScore({required this.match});

  @override
  Widget build(BuildContext context) {
    final sets = [
      ...match.completedSets.map((s) => (s.t1, s.t2)),
      if (match.status == MatchStatus.active)
        (match.currentSetT1, match.currentSetT2),
    ];

    if (sets.isEmpty) {
      return Text('–', style: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white24));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sets.map((s) {
        final t1Leads = s.$1 > s.$2;
        final t2Leads = s.$2 > s.$1;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${s.$1}',
                style: GoogleFonts.inter(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: t1Leads ? team1Color : Colors.white38,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('–',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white24, fontWeight: FontWeight.w600)),
            ),
            Text('${s.$2}',
                style: GoogleFonts.inter(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: t2Leads ? team2Color : Colors.white38,
                )),
          ]),
        );
      }).toList(),
    );
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
