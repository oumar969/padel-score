import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/match_model.dart';
import '../providers/match_provider.dart';

class ScoreScreen extends ConsumerWidget {
  final String matchId;
  const ScoreScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchProvider(matchId));
    return matchAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fejl: $e'))),
      data: (match) => _ScoreView(match: match),
    );
  }
}

class _ScoreView extends ConsumerStatefulWidget {
  final PadelMatch match;
  const _ScoreView({required this.match});

  @override
  ConsumerState<_ScoreView> createState() => _ScoreViewState();
}

class _ScoreViewState extends ConsumerState<_ScoreView>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  int? _lastT1;
  int? _lastT2;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _lastT1 = widget.match.currentGameT1;
    _lastT2 = widget.match.currentGameT2;
  }

  @override
  void didUpdateWidget(_ScoreView old) {
    super.didUpdateWidget(old);
    final m = widget.match;
    if (m.currentGameT1 != _lastT1 || m.currentGameT2 != _lastT2) {
      _lastT1 = m.currentGameT1;
      _lastT2 = m.currentGameT2;
      _flashController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final canUndo = ref.watch(canUndoProvider(match.id));
    final actions = ref.read(matchActionsProvider);
    final isFinished = match.status == MatchStatus.finished;

    Future<void> onTap(int team) async {
      if (isFinished) return;
      HapticFeedback.mediumImpact();
      await actions.awardPoint(match, team);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              _TopBar(match: match, canUndo: canUndo, actions: actions),
              Expanded(
                child: Row(
                  children: [
                    _TeamPanel(
                      team: 1,
                      match: match,
                      flashController: _flashController,
                      onTap: () => onTap(1),
                    ),
                    _CenterDivider(match: match),
                    _TeamPanel(
                      team: 2,
                      match: match,
                      flashController: _flashController,
                      onTap: () => onTap(2),
                    ),
                  ],
                ),
              ),
              _StatusBar(match: match),
            ],
          ),
          if (isFinished) _WinOverlay(match: match),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final PadelMatch match;
  final bool canUndo;
  final MatchActions actions;
  const _TopBar({required this.match, required this.canUndo, required this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: Colors.white54,
              onPressed: () => context.pop(),
            ),
            Expanded(child: _SetRow(match: match)),
            AnimatedOpacity(
              opacity: canUndo ? 1 : 0.2,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: const Icon(Icons.undo_rounded, size: 22),
                color: Colors.white70,
                onPressed: canUndo ? () => actions.undo(match.id) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final PadelMatch match;
  const _SetRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final sets = match.completedSets;
    final hasCurrentSet = match.status == MatchStatus.active &&
        (match.currentSetT1 > 0 || match.currentSetT2 > 0 || sets.isEmpty);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...sets.asMap().entries.map((e) => _SetChip(
              t1: e.value.t1,
              t2: e.value.t2,
              current: false,
            )),
        if (hasCurrentSet)
          _SetChip(
            t1: match.currentSetT1,
            t2: match.currentSetT2,
            current: true,
          ),
      ],
    );
  }
}

class _SetChip extends StatelessWidget {
  final int t1, t2;
  final bool current;
  const _SetChip({required this.t1, required this.t2, required this.current});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: current ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: current
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Text(
        '$t1 - $t2',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: current ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}

class _TeamPanel extends StatelessWidget {
  final int team;
  final PadelMatch match;
  final AnimationController flashController;
  final VoidCallback onTap;

  const _TeamPanel({
    required this.team,
    required this.match,
    required this.flashController,
    required this.onTap,
  });

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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isT1 ? Alignment.centerRight : Alignment.centerLeft,
              end: isT1 ? Alignment.centerLeft : Alignment.centerRight,
              colors: [
                darkColor.withValues(alpha: 0.35),
                bgColor,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Team name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  name.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Animated score number
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween<double>(begin: 0.75, end: 1).animate(
                    CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  score,
                  key: ValueKey('$team-$score'),
                  style: GoogleFonts.inter(
                    fontSize: 108,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                    height: 1,
                    color: hasAdv
                        ? color
                        : isWinning
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                    shadows: hasAdv
                        ? [
                            Shadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 30,
                            )
                          ]
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sets won as dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 2; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i < sets ? 24 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i < sets
                            ? color
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 28),

              // Tap hint
              if (match.status == MatchStatus.active)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 14,
                        color: color.withValues(alpha: 0.25)),
                    const SizedBox(width: 4),
                    Text(
                      'TAP',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: color.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterDivider extends StatelessWidget {
  final PadelMatch match;
  const _CenterDivider({required this.match});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final PadelMatch match;
  const _StatusBar({required this.match});

  @override
  Widget build(BuildContext context) {
    String label = '';
    Color color = Colors.white38;

    if (match.isDeuce) {
      label = 'DEUCE';
      color = goldColor.withValues(alpha: 0.8);
    } else if (match.team1HasAdvantage) {
      label = 'AD ${match.team1Name.toUpperCase()}';
      color = team1Color;
    } else if (match.team2HasAdvantage) {
      label = 'AD ${match.team2Name.toUpperCase()}';
      color = team2Color;
    } else if (match.isTiebreak) {
      label = 'TIEBREAK';
      color = goldColor.withValues(alpha: 0.8);
    }

    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 44,
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: label.isEmpty
              ? const SizedBox.shrink()
              : Text(
                  label,
                  key: ValueKey(label),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: color,
                  ),
                ),
        ),
      ),
    );
  }
}

class _WinOverlay extends StatelessWidget {
  final PadelMatch match;
  const _WinOverlay({required this.match});

  @override
  Widget build(BuildContext context) {
    final isT1 = match.winner == 1;
    final name = isT1 ? match.team1Name : match.team2Name;
    final color = isT1 ? team1Color : team2Color;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                color.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.92),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: goldColor.withValues(alpha: 0.12),
                  border: Border.all(
                      color: goldColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    size: 48, color: goldColor),
              ),
              const SizedBox(height: 28),

              Text(
                'VINDER',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 16),

              // Set scores
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: match.completedSets
                    .map((s) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${s.t1}-${s.t2}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white38,
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 56),

              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  foregroundColor: Colors.white60,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Tilbage til oversigt',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
