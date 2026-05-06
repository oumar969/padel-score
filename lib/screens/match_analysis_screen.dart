import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/match_analysis.dart';
import '../models/match_model.dart';
import '../providers/match_provider.dart';

class MatchAnalysisScreen extends ConsumerWidget {
  final String matchId;
  const MatchAnalysisScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchProvider(matchId));
    return matchAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fejl: $e'))),
      data: (match) => _AnalysisBody(match: match),
    );
  }
}

class _AnalysisBody extends StatelessWidget {
  final PadelMatch match;
  const _AnalysisBody({required this.match});

  @override
  Widget build(BuildContext context) {
    final analysis = MatchAnalysis(match);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white54,
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Analyse', style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('${match.team1Name}  ·  ${match.team2Name}',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
        ]),
      ),
      body: match.gameLog.isEmpty
          ? _EmptyAnalysis()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(children: [
                _MomentumCard(analysis: analysis),
                const SizedBox(height: 16),
                _HeatmapCard(analysis: analysis),
                const SizedBox(height: 16),
                _RecordsCard(analysis: analysis),
              ]),
            ),
    );
  }
}

// ── Section container ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text(title, style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 2, color: Colors.white38)),
        ),
        child,
      ]),
    );
  }
}

// ── Momentum chart ────────────────────────────────────────────────────────────

class _MomentumCard extends StatelessWidget {
  final MatchAnalysis analysis;
  const _MomentumCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final pts = analysis.momentumPoints;
    final match = analysis.match;

    return _SectionCard(
      title: 'MOMENTUM',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _TeamChip(color: team1Color, name: match.team1Name),
            const Spacer(),
            _TeamChip(color: team2Color, name: match.team2Name, rightAlign: true),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _MomentumPainter(
                  points: pts, peak: analysis.maxAbsMomentum),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('Start', style: GoogleFonts.inter(fontSize: 10, color: Colors.white24)),
            const Spacer(),
            Text('${match.gameLog.length} spil',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white24)),
          ]),
        ]),
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  final Color color;
  final String name;
  final bool rightAlign;
  const _TeamChip({required this.color, required this.name, this.rightAlign = false});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    return Row(mainAxisSize: MainAxisSize.min, children: rightAlign
        ? [
            Text(name, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(width: 6),
            dot,
          ]
        : [
            dot,
            const SizedBox(width: 6),
            Text(name, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ]);
  }
}

class _MomentumPainter extends CustomPainter {
  final List<int> points;
  final int peak;
  const _MomentumPainter({required this.points, required this.peak});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final n = points.length - 1;
    final scale = (size.height * 0.42) / peak;
    final cy = size.height / 2;

    double xAt(int i) => i * size.width / n;
    double yAt(int v) => (cy - v * scale).clamp(2.0, size.height - 2.0);

    // Zero line
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy),
        Paint()..color = Colors.white.withValues(alpha:0.08)..strokeWidth = 1);

    // Build path
    final path = Path()..moveTo(xAt(0), yAt(points[0]));
    for (int i = 1; i < points.length; i++) {
      path.lineTo(xAt(i), yAt(points[i]));
    }

    // Fill above zero (team1)
    final fill1 = Path.from(path)
      ..lineTo(size.width, cy)
      ..lineTo(0, cy)
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, cy));
    canvas.drawPath(fill1, Paint()
      ..color = team1Color.withValues(alpha:0.12)
      ..style = PaintingStyle.fill);
    canvas.restore();

    // Fill below zero (team2)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, cy, size.width, size.height - cy));
    canvas.drawPath(fill1, Paint()
      ..color = team2Color.withValues(alpha:0.12)
      ..style = PaintingStyle.fill);
    canvas.restore();

    // Line segments colored by which team is leading
    final linePaint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < points.length; i++) {
      final avg = (points[i - 1] + points[i]) / 2;
      linePaint.color =
          avg > 0 ? team1Color : avg < 0 ? team2Color : Colors.white38;
      canvas.drawLine(
        Offset(xAt(i - 1), yAt(points[i - 1])),
        Offset(xAt(i), yAt(points[i])),
        linePaint,
      );
    }

    // End dot
    if (points.isNotEmpty) {
      final last = points.last;
      canvas.drawCircle(
        Offset(xAt(points.length - 1), yAt(last)),
        5,
        Paint()
          ..color =
              last > 0 ? team1Color : last < 0 ? team2Color : Colors.white38,
      );
    }
  }

  @override
  bool shouldRepaint(_MomentumPainter old) =>
      old.points != points || old.peak != peak;
}

// ── Set heatmap ───────────────────────────────────────────────────────────────

class _HeatmapCard extends StatelessWidget {
  final MatchAnalysis analysis;
  const _HeatmapCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final setWinners = analysis.setGameWinners;
    final match = analysis.match;

    return _SectionCard(
      title: 'SÆT HEATMAP',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (setWinners.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Ingen afsluttede sæt endnu',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white30)),
            )
          else
            ...List.generate(setWinners.length, (s) {
              final games = setWinners[s];
              final score = match.completedSets[s];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('SÆT ${s + 1}',
                        style: GoogleFonts.inter(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            letterSpacing: 1.5, color: Colors.white38)),
                    const SizedBox(width: 8),
                    Text('${score.t1}–${score.t2}',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Colors.white70)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(games.length, (g) {
                      final color = games[g] == 1 ? team1Color : team2Color;
                      return Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withValues(alpha:0.5)),
                        ),
                        child: Center(
                          child: Text('${g + 1}',
                              style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                      );
                    }),
                  ),
                ]),
              );
            }),
          const SizedBox(height: 4),
          Row(children: [
            _HeatmapLegend(color: team1Color, label: match.team1Name),
            const SizedBox(width: 16),
            _HeatmapLegend(color: team2Color, label: match.team2Name),
          ]),
        ]),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _HeatmapLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.25),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha:0.6)),
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
    ]);
  }
}

// ── Records ───────────────────────────────────────────────────────────────────

class _RecordsCard extends StatelessWidget {
  final MatchAnalysis analysis;
  const _RecordsCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final streak = analysis.longestStreak;
    final comebacks = analysis.comebacks;
    final match = analysis.match;
    final streakName =
        streak.team == 1 ? match.team1Name : match.team2Name;
    final streakColor = streak.team == 1 ? team1Color : team2Color;

    return _SectionCard(
      title: 'REKORDER',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(children: [
          _RecordRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: goldColor,
            label: 'LÆNGSTE SEJRSRÆKKE',
            value: streak.count > 0
                ? '$streakName vandt ${streak.count} spil i træk'
                : 'Ingen data',
            valueColor: streak.count > 0 ? streakColor : Colors.white30,
          ),
          const SizedBox(height: 16),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 16),
          if (comebacks.isEmpty)
            _RecordRow(
              icon: Icons.trending_up_rounded,
              iconColor: Colors.white24,
              label: 'COMEBACK',
              value: 'Ingen comeback i denne kamp',
              valueColor: Colors.white30,
            )
          else
            ...comebacks.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: e.key < comebacks.length - 1 ? 12 : 0),
              child: _RecordRow(
                icon: Icons.trending_up_rounded,
                iconColor: goldColor,
                label: 'COMEBACK',
                value: e.value,
                valueColor: Colors.white70,
              ),
            )),
        ]),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _RecordRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w700,
              letterSpacing: 1.5, color: Colors.white38)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
        ]),
      ),
    ]);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyAnalysis extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha:0.04),
            border: Border.all(color: Colors.white.withValues(alpha:0.08)),
          ),
          child: const Icon(Icons.bar_chart_rounded, size: 36, color: Colors.white12),
        ),
        const SizedBox(height: 20),
        Text('Ingen data endnu', style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white30)),
        const SizedBox(height: 8),
        Text('Data registreres automatisk under kampen',
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white.withValues(alpha:0.2))),
      ]),
    );
  }
}
