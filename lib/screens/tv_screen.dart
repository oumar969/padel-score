import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/match_model.dart';
import '../providers/match_provider.dart';

class TvScreen extends ConsumerWidget {
  final String matchId;
  const TvScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchProvider(matchId));
    return Scaffold(
      backgroundColor: Colors.black,
      body: matchAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: team1Color),
        ),
        error: (e, _) => Center(
          child: Text('Match ikke fundet',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 24)),
        ),
        data: (match) => _TvView(match: match),
      ),
    );
  }
}

class _TvView extends ConsumerStatefulWidget {
  final PadelMatch match;
  const _TvView({required this.match});

  @override
  ConsumerState<_TvView> createState() => _TvViewState();
}

class _TvViewState extends ConsumerState<_TvView> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final timer = ref.watch(matchTimerProvider(match.id)).valueOrNull ?? '00:00';
    final isFinished = match.status == MatchStatus.finished;

    return Stack(
      children: [
        Column(
          children: [
            _TvTopBar(match: match, timer: timer),
            Expanded(
              child: Row(
                children: [
                  _TvPanel(team: 1, match: match),
                  _TvDivider(match: match),
                  _TvPanel(team: 2, match: match),
                ],
              ),
            ),
            _TvStatusBar(match: match),
          ],
        ),
        if (isFinished) _TvWinOverlay(match: match),
      ],
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TvTopBar extends StatelessWidget {
  final PadelMatch match;
  final String timer;
  const _TvTopBar({required this.match, required this.timer});

  @override
  Widget build(BuildContext context) {
    final sets = match.completedSets;
    final hasCurrent = match.status == MatchStatus.active &&
        (match.currentSetT1 > 0 || match.currentSetT2 > 0 || sets.isEmpty);

    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: Row(
        children: [
          // Set history
          Row(
            children: [
              ...sets.map((s) => _SetBadge(t1: s.t1, t2: s.t2, current: false)),
              if (hasCurrent)
                _SetBadge(
                    t1: match.currentSetT1, t2: match.currentSetT2, current: true),
            ],
          ),

          const Spacer(),

          // Timer
          if (match.matchStartedAt != null)
            Row(children: [
              Icon(Icons.timer_outlined, size: 18,
                  color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 6),
              Text(timer,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 2,
                  )),
            ]),
        ],
      ),
    );
  }
}

class _SetBadge extends StatelessWidget {
  final int t1, t2;
  final bool current;
  const _SetBadge({required this.t1, required this.t2, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: current
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: current
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text('$t1  –  $t2',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: current ? Colors.white : Colors.white38,
            letterSpacing: 2,
          )),
    );
  }
}

// ── Team panel ────────────────────────────────────────────────────────────────

class _TvPanel extends StatelessWidget {
  final int team;
  final PadelMatch match;
  const _TvPanel({required this.team, required this.match});

  @override
  Widget build(BuildContext context) {
    final isT1 = team == 1;
    final color = isT1 ? team1Color : team2Color;
    final darkColor = isT1 ? team1Dark : team2Dark;
    final name = isT1 ? match.team1Name : match.team2Name;
    final score = isT1 ? match.team1GameDisplay : match.team2GameDisplay;
    final sets = isT1 ? match.team1Sets : match.team2Sets;
    final hasAdv = isT1 ? match.team1HasAdvantage : match.team2HasAdvantage;
    final isWinning = isT1
        ? match.currentGameT1 > match.currentGameT2
        : match.currentGameT2 > match.currentGameT1;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isT1 ? Alignment.centerRight : Alignment.centerLeft,
            end: isT1 ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              darkColor.withValues(alpha: 0.4),
              Colors.black,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Team name
            Text(
              name.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: color.withValues(alpha: 0.8),
              ),
            ),

            const SizedBox(height: 16),

            // Score — fills available space
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.elasticOut)),
                    child: child,
                  ),
                  child: Text(
                    score,
                    key: ValueKey('$team-$score'),
                    style: GoogleFonts.inter(
                      fontSize: 280,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: hasAdv
                          ? color
                          : isWinning
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                      shadows: hasAdv
                          ? [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 60)]
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sets won
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: i < sets ? 40 : 16,
                height: 16,
                decoration: BoxDecoration(
                  color: i < sets ? color : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Center divider ────────────────────────────────────────────────────────────

class _TvDivider extends StatelessWidget {
  final PadelMatch match;
  const _TvDivider({required this.match});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status bar ────────────────────────────────────────────────────────────────

class _TvStatusBar extends StatelessWidget {
  final PadelMatch match;
  const _TvStatusBar({required this.match});

  @override
  Widget build(BuildContext context) {
    String label = '';
    Color color = Colors.white38;

    if (match.isDeuce) { label = 'DEUCE'; color = goldColor; }
    else if (match.team1HasAdvantage) { label = 'AD  ${match.team1Name.toUpperCase()}'; color = team1Color; }
    else if (match.team2HasAdvantage) { label = 'AD  ${match.team2Name.toUpperCase()}'; color = team2Color; }
    else if (match.isTiebreak) { label = 'TIEBREAK'; color = goldColor; }

    return Container(
      color: const Color(0xFF0A0A0A),
      height: 52,
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: label.isEmpty
            ? const SizedBox.shrink()
            : Text(label,
                key: ValueKey(label),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: color,
                )),
      ),
    );
  }
}

// ── Win overlay ───────────────────────────────────────────────────────────────

class _TvWinOverlay extends StatelessWidget {
  final PadelMatch match;
  const _TvWinOverlay({required this.match});

  @override
  Widget build(BuildContext context) {
    final isT1 = match.winner == 1;
    final name = isT1 ? match.team1Name : match.team2Name;
    final color = isT1 ? team1Color : team2Color;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.5,
            colors: [color.withValues(alpha: 0.25), Colors.black.withValues(alpha: 0.95)],
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.emoji_events_rounded, size: 120, color: goldColor),
          const SizedBox(height: 24),
          Text('VINDER', style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w700,
            letterSpacing: 6, color: color.withValues(alpha: 0.7),
          )),
          const SizedBox(height: 12),
          Text(name.toUpperCase(), style: GoogleFonts.inter(
            fontSize: 96, fontWeight: FontWeight.w900,
            letterSpacing: -2, color: Colors.white,
          )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: match.completedSets.map((s) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('${s.t1} – ${s.t2}', style: GoogleFonts.inter(
                fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white38,
              )),
            )).toList(),
          ),
        ]),
      ),
    );
  }
}
