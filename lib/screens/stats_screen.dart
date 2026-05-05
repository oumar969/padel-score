import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/player_stats.dart';
import '../providers/match_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(playerStatsProvider);
    final matchesAsync = ref.watch(matchesProvider);

    final totalMatches = matchesAsync.valueOrNull?.length ?? 0;
    final finishedMatches = matchesAsync.valueOrNull
            ?.where((m) => m.status.name == 'finished')
            .length ??
        0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 120,
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
            // Summary row
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(children: [
                  _SummaryChip(label: 'Spillere', value: '${stats.length}'),
                  const SizedBox(width: 10),
                  _SummaryChip(label: 'Kampe spillet', value: '$totalMatches'),
                  const SizedBox(width: 10),
                  _SummaryChip(label: 'Afsluttet', value: '$finishedMatches'),
                ]),
              ),
            ),

            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _TableHeader(),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _PlayerCard(stats: stats[i], rank: i + 1),
                  childCount: stats.length,
                ),
              ),
            ),
          ],
        ],
      ),
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
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dividerColor),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white,
          )),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(
            fontSize: 11, color: Colors.white38,
          )),
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
        : rank == 2
            ? const Color(0xFFB0BEC5)
            : rank == 3
                ? const Color(0xFFBF8970)
                : Colors.white24;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? rankColor.withValues(alpha: 0.2) : dividerColor,
          width: isTop ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Rank
        SizedBox(
          width: 32,
          child: Text('$rank',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w800, color: rankColor)),
        ),

        // Name + best partner
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stats.name,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            if (stats.bestPartner != null)
              Text('Bedst med ${stats.bestPartner}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white30)),
          ]),
        ),

        // Wins
        SizedBox(
          width: 44,
          child: Text('${stats.wins}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700, color: team1Color)),
        ),

        // Losses
        SizedBox(
          width: 44,
          child: Text('${stats.losses}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700, color: team2Color)),
        ),

        // Win rate
        SizedBox(
          width: 44,
          child: Text(stats.winRatePct,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white60)),
        ),
      ]),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Icon(Icons.leaderboard_rounded, size: 40, color: Colors.white12),
      ),
      const SizedBox(height: 20),
      Text('Ingen statistik endnu',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white30)),
      const SizedBox(height: 8),
      Text('Spil og afslut kampe for at se statistik',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.2))),
    ]);
  }
}
