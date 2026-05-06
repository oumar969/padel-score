import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../models/comment_model.dart';
import '../models/match_model.dart';
import '../providers/match_provider.dart';

class ScoreScreen extends ConsumerWidget {
  final String matchId;
  const ScoreScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchProvider(matchId));
    final ownerAsync = ref.watch(isMatchOwnerProvider(matchId));
    final isOwner = ownerAsync.valueOrNull ?? false;

    return matchAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fejl: $e'))),
      data: (match) => _ScoreView(match: match, isOwner: isOwner),
    );
  }
}

// ── Main view ─────────────────────────────────────────────────────────────────

class _ScoreView extends ConsumerStatefulWidget {
  final PadelMatch match;
  final bool isOwner;
  const _ScoreView({required this.match, required this.isOwner});

  @override
  ConsumerState<_ScoreView> createState() => _ScoreViewState();
}

class _ScoreViewState extends ConsumerState<_ScoreView>
    with SingleTickerProviderStateMixin {
  late AnimationController _flash;
  int? _lastT1, _lastT2;
  bool _ballReminderDismissed = false;
  int _lastGames = 0;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _lastT1 = widget.match.currentGameT1;
    _lastT2 = widget.match.currentGameT2;
    _lastGames = widget.match.totalGamesPlayed;
  }

  @override
  void didUpdateWidget(_ScoreView old) {
    super.didUpdateWidget(old);
    final m = widget.match;
    if (m.currentGameT1 != _lastT1 || m.currentGameT2 != _lastT2) {
      _lastT1 = m.currentGameT1; _lastT2 = m.currentGameT2;
      _flash.forward(from: 0);
    }
    // Reset ball reminder dismiss when game count changes
    if (m.totalGamesPlayed != _lastGames) {
      _lastGames = m.totalGamesPlayed;
      _ballReminderDismissed = false;
    }
  }

  @override
  void dispose() { _flash.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isOwner = widget.isOwner;
    final isFinished = match.status == MatchStatus.finished;
    final actions = ref.read(matchActionsProvider);
    final canUndo = ref.watch(canUndoProvider(match.id));
    final timer = ref.watch(matchTimerProvider(match.id)).valueOrNull ?? '00:00';
    final warmupLeft = ref.watch(warmupTickProvider(match.id)).valueOrNull ?? Duration.zero;
    final timeoutLeft = ref.watch(timeoutTickProvider(match.id)).valueOrNull ?? Duration.zero;
    final showBallReminder = match.needsBallReminder && !_ballReminderDismissed;

    Future<void> onTap(int team) async {
      if (!isOwner || isFinished || match.isInTimeout || match.isInWarmup) return;
      HapticFeedback.mediumImpact();
      await actions.awardPoint(match, team);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Main score UI
          Column(children: [
            _TopBar(match: match, canUndo: canUndo && isOwner,
                actions: actions, timer: timer, isOwner: isOwner),
            if (showBallReminder)
              _BallReminderBanner(onDismiss: () => setState(() => _ballReminderDismissed = true)),
            Expanded(
              child: Row(children: [
                _TeamPanel(team: 1, match: match, flashCtrl: _flash,
                    onTap: () => onTap(1), isOwner: isOwner),
                _CenterDivider(match: match),
                _TeamPanel(team: 2, match: match, flashCtrl: _flash,
                    onTap: () => onTap(2), isOwner: isOwner),
              ]),
            ),
            _StatusBar(match: match),
          ]),

          // Warmup overlay
          if (match.isInWarmup)
            _WarmupOverlay(remaining: warmupLeft, isOwner: isOwner,
                onSkip: () => actions.endWarmup(match)),

          // Timeout overlay
          if (match.isInTimeout)
            _TimeoutOverlay(remaining: timeoutLeft, isOwner: isOwner,
                onEnd: () => actions.endTimeout(match)),

          // Win overlay
          if (isFinished) _WinOverlay(match: match),
        ],
      ),
      // Comments FAB
      floatingActionButton: match.settings.liveComments
          ? _CommentsFab(match: match, isOwner: isOwner)
          : null,
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final PadelMatch match;
  final bool canUndo, isOwner;
  final MatchActions actions;
  final String timer;
  const _TopBar({required this.match, required this.canUndo,
      required this.actions, required this.timer, required this.isOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Column(children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: Colors.white54,
              onPressed: () => context.pop(),
            ),
            Expanded(child: _SetRow(match: match)),

            if (!isOwner)
              _LiveBadge()
            else ...[
              // Timeout button
              if (match.settings.timeout && !match.isInTimeout)
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.15),
                    foregroundColor: Colors.orange,
                  ),
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                  onPressed: () => actions.startTimeout(match),
                ),
              // Share / TV
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: team1Color.withValues(alpha: 0.15),
                  foregroundColor: team1Color,
                ),
                icon: const Icon(Icons.tv_rounded, size: 18),
                onPressed: () => _showShareDialog(context, match.id),
              ),
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
          ]),
          if (match.matchStartedAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.timer_outlined, size: 13,
                    color: Colors.white.withValues(alpha: 0.25)),
                const SizedBox(width: 4),
                Text(timer, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.25), letterSpacing: 1)),
              ]),
            ),
        ]),
      ),
    );
  }
}

// ── Team panel ────────────────────────────────────────────────────────────────

class _TeamPanel extends StatelessWidget {
  final int team;
  final PadelMatch match;
  final AnimationController flashCtrl;
  final VoidCallback onTap;
  final bool isOwner;

  const _TeamPanel({required this.team, required this.match,
      required this.flashCtrl, required this.onTap, required this.isOwner});

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
    final isServing = match.settings.serveIndicator && match.servingTeam == team;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isT1 ? Alignment.centerRight : Alignment.centerLeft,
              end: isT1 ? Alignment.centerLeft : Alignment.centerRight,
              colors: [darkColor.withValues(alpha: 0.35), bgColor],
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Serve indicator
            if (isServing)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('🎾', style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text('SERVE', style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        letterSpacing: 2, color: color)),
                  ]),
                ),
              ),

            // Team name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(name.toUpperCase(),
                textAlign: TextAlign.center, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    letterSpacing: 2, color: color.withValues(alpha: 0.8))),
            ),

            const SizedBox(height: 12),

            // Score
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.75, end: 1).animate(
                    CurvedAnimation(parent: anim, curve: Curves.elasticOut)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(score, key: ValueKey('$team-$score'),
                style: GoogleFonts.inter(
                  fontSize: 108, fontWeight: FontWeight.w900,
                  letterSpacing: -4, height: 1,
                  color: hasAdv ? color : isWinning ? Colors.white : Colors.white.withValues(alpha: 0.55),
                  shadows: hasAdv ? [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 30)] : null,
                )),
            ),

            const SizedBox(height: 20),

            // Set dots
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (int i = 0; i < 2; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i < sets ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i < sets ? color : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
            ]),

            const SizedBox(height: 28),

            if (match.status == MatchStatus.active)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(isOwner ? Icons.touch_app_rounded : Icons.visibility_rounded,
                    size: 14, color: color.withValues(alpha: 0.25)),
                const SizedBox(width: 4),
                Text(isOwner ? 'TAP' : 'TILSKUER', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    letterSpacing: 2, color: color.withValues(alpha: 0.25))),
              ]),
          ]),
        ),
      ),
    );
  }
}

// ── Ball reminder banner ──────────────────────────────────────────────────────

class _BallReminderBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _BallReminderBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1500),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        const Text('🔔', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: Text('Tid til boldbytte!', style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700, color: goldColor))),
        GestureDetector(
          onTap: onDismiss,
          child: const Icon(Icons.close_rounded, size: 18, color: Colors.white38),
        ),
      ]),
    );
  }
}

// ── Warmup overlay ────────────────────────────────────────────────────────────

class _WarmupOverlay extends StatelessWidget {
  final Duration remaining;
  final bool isOwner;
  final VoidCallback onSkip;
  const _WarmupOverlay({required this.remaining, required this.isOwner, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🎾', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text('OPVARMNING', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w800,
              letterSpacing: 4, color: Colors.white38)),
          const SizedBox(height: 12),
          Text('$m:$s', style: GoogleFonts.inter(
              fontSize: 80, fontWeight: FontWeight.w900,
              color: team1Color, letterSpacing: -2)),
          const SizedBox(height: 32),
          if (isOwner)
            OutlinedButton(
              onPressed: onSkip,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                foregroundColor: Colors.white54,
              ),
              child: Text('Spring over', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
    );
  }
}

// ── Timeout overlay ───────────────────────────────────────────────────────────

class _TimeoutOverlay extends StatelessWidget {
  final Duration remaining;
  final bool isOwner;
  final VoidCallback onEnd;
  const _TimeoutOverlay({required this.remaining, required this.isOwner, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    final s = remaining.inSeconds.toString().padLeft(2, '0');
    final progress = remaining.inSeconds / 60;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.82),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('TIMEOUT', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w800,
              letterSpacing: 4, color: Colors.orange.withValues(alpha: 0.7))),
          const SizedBox(height: 24),
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 160, height: 160,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                color: Colors.orange,
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
              ),
            ),
            Text(s, style: GoogleFonts.inter(
                fontSize: 64, fontWeight: FontWeight.w900,
                color: Colors.orange, letterSpacing: -2)),
          ]),
          const SizedBox(height: 32),
          if (isOwner)
            OutlinedButton(
              onPressed: onEnd,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                foregroundColor: Colors.orange,
              ),
              child: Text('Fortsæt kamp', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }
}

// ── Comments FAB + bottom sheet ───────────────────────────────────────────────

class _CommentsFab extends ConsumerWidget {
  final PadelMatch match;
  final bool isOwner;
  const _CommentsFab({required this.match, required this.isOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(commentsProvider(match.id)).valueOrNull ?? [];
    return FloatingActionButton(
      backgroundColor: cardColor,
      foregroundColor: Colors.white70,
      mini: true,
      onPressed: () => _openComments(context, ref),
      child: Stack(alignment: Alignment.center, children: [
        const Icon(Icons.chat_bubble_outline_rounded),
        if (comments.isNotEmpty)
          Positioned(
            top: 6, right: 6,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: team1Color, shape: BoxShape.circle),
            ),
          ),
      ]),
    );
  }

  void _openComments(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CommentsSheet(match: match, isOwner: isOwner),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final PadelMatch match;
  final bool isOwner;
  const _CommentsSheet({required this.match, required this.isOwner});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  String? _replyingToId; // comment id being replied to

  final _quickReactions = ['🔥 Nice shot!', '💪 Let\'s go!', '😮 Wow!', '👏 Godt spillet!', '😂 Haha!'];

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send(String text, {bool isReply = false, String? replyToId}) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() => _replyingToId = null);
    await ref.read(matchActionsProvider).addComment(
      widget.match.id, text.trim(),
      isOwnerReply: isReply,
      replyToId: replyToId,
    );
    if (_scroll.hasClients && _scroll.position.hasContentDimensions) {
      _scroll.animateTo(_scroll.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.isOwner;
    final comments = ref.watch(commentsProvider(widget.match.id)).valueOrNull ?? [];
    // Top-level comments only (no replies in main list)
    final topLevel = comments.where((c) => c.replyToId == null).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(children: [
            Text('💬  Kommentarer', style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const Spacer(),
            if (isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: team1Color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('SPILLER', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    letterSpacing: 1, color: team1Color)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: team2Color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('TILSKUER', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    letterSpacing: 1, color: team2Color)),
              ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFF2A2A40)),

        // Quick reactions — kun tilskuere
        if (!isOwner)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: _quickReactions.map((r) => GestureDetector(
              onTap: () => _send(r),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dividerColor),
                ),
                child: Text(r, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
              ),
            )).toList()),
          ),

        // Info til ejer
        if (isOwner && topLevel.isEmpty)
          const SizedBox(height: 8),
        if (isOwner && topLevel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Tryk "Svar" for at svare på en kommentar',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white24)),
          ),

        // Comment list
        Expanded(
          child: topLevel.isEmpty
              ? Center(child: Text(
                  isOwner ? 'Ingen kommentarer endnu' : 'Vær den første til at kommentere!',
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 14)))
              : ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: topLevel.length,
                  itemBuilder: (_, i) {
                    final c = topLevel[i];
                    final replies = comments.where((r) => r.replyToId == c.id).toList();
                    return _CommentTile(
                      comment: c,
                      replies: replies,
                      isOwner: isOwner,
                      isReplying: _replyingToId == c.id,
                      onReply: isOwner
                          ? () => setState(() {
                                _replyingToId = c.id;
                                _ctrl.clear();
                              })
                          : null,
                    );
                  }),
        ),

        // Input — tilskuere skriver nyt, ejer svarer
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
            child: !isOwner
                ? _TextInput(
                    ctrl: _ctrl,
                    hint: 'Skriv en kommentar...',
                    onSend: (t) => _send(t),
                  )
                : _replyingToId != null
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          const Icon(Icons.reply_rounded, size: 14, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text('Svarer...', style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.white38)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() { _replyingToId = null; _ctrl.clear(); }),
                            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        _TextInput(
                          ctrl: _ctrl,
                          hint: 'Dit svar...',
                          onSend: (t) => _send(t, isReply: true, replyToId: _replyingToId),
                          accentColor: team1Color,
                        ),
                      ])
                    : const SizedBox.shrink(),
          ),
        ),
      ]),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final MatchComment comment;
  final List<MatchComment> replies;
  final bool isOwner;
  final bool isReplying;
  final VoidCallback? onReply;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.isOwner,
    required this.isReplying,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Comment bubble
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: team2Color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, size: 16, color: team2Color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor),
                ),
                child: Text(comment.text, style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.white)),
              ),
              if (isOwner && !isReplying)
                GestureDetector(
                  onTap: onReply,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text('Svar', style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: team1Color)),
                  ),
                ),
            ]),
          ),
        ]),

        // Replies
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 42, top: 6),
            child: Column(children: replies.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: team1Color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.sports_tennis_rounded, size: 13, color: team1Color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: team1Color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: team1Color.withValues(alpha: 0.2)),
                    ),
                    child: Text(r.text, style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white)),
                  ),
                ),
              ]),
            )).toList()),
          ),
      ]),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final ValueChanged<String> onSend;
  final Color accentColor;

  const _TextInput({
    required this.ctrl,
    required this.hint,
    required this.onSend,
    this.accentColor = team1Color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: ctrl,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white38),
            filled: true, fillColor: cardColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: onSend,
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        style: IconButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white),
        icon: const Icon(Icons.send_rounded, size: 18),
        onPressed: () => onSend(ctrl.text),
      ),
    ]);
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final PadelMatch match;
  const _SetRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final sets = match.completedSets;
    final hasCurrent = match.status == MatchStatus.active &&
        (match.currentSetT1 > 0 || match.currentSetT2 > 0 || sets.isEmpty);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      ...sets.map((s) => _SetChip(t1: s.t1, t2: s.t2, current: false)),
      if (hasCurrent) _SetChip(t1: match.currentSetT1, t2: match.currentSetT2, current: true),
    ]);
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
        border: Border.all(color: current
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text('$t1 - $t2', style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: current ? Colors.white : Colors.white38)),
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.15),
              Colors.transparent,
            ],
          ),
        ),
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
    if (match.isDeuce) { label = 'DEUCE'; color = goldColor.withValues(alpha: 0.8); }
    else if (match.team1HasAdvantage) { label = 'AD ${match.team1Name.toUpperCase()}'; color = team1Color; }
    else if (match.team2HasAdvantage) { label = 'AD ${match.team2Name.toUpperCase()}'; color = team2Color; }
    else if (match.isTiebreak) { label = 'TIEBREAK'; color = goldColor.withValues(alpha: 0.8); }

    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 44, alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: label.isEmpty ? const SizedBox.shrink()
              : Text(label, key: ValueKey(label), style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  letterSpacing: 2.5, color: color)),
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
            gradient: RadialGradient(radius: 1.2, colors: [
              color.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.92)]),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: goldColor.withValues(alpha: 0.12),
                border: Border.all(color: goldColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.emoji_events_rounded, size: 48, color: goldColor),
            ),
            const SizedBox(height: 28),
            Text('VINDER', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700,
                letterSpacing: 4, color: color.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            Text(name, style: GoogleFonts.inter(
                fontSize: 44, fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: -1)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: match.completedSets.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('${s.t1}-${s.t2}', style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white38)),
                )).toList()),
            const SizedBox(height: 56),
            OutlinedButton.icon(
              onPressed: () => context.push('/match/${match.id}/analysis'),
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: Text('Se analyse',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: team1Color),
                foregroundColor: team1Color,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                foregroundColor: Colors.white60,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Tilbage til oversigt',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: team2Color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: team2Color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
            child: Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: team2Color, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 6),
          Text('LIVE', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800,
              letterSpacing: 1.5, color: team2Color)),
        ]),
      ),
    );
  }
}

// ── Share dialog ──────────────────────────────────────────────────────────────

void _copyUrl(BuildContext context, String url) {
  Clipboard.setData(ClipboardData(text: url));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Kopieret!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
    backgroundColor: team1Color, behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}

Widget _urlTile(BuildContext context, String label, String url, IconData icon) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38, letterSpacing: 1)),
    const SizedBox(height: 6),
    GestureDetector(
      onTap: () => _copyUrl(context, url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: team1Color),
          const SizedBox(width: 10),
          Expanded(child: Text(url, style: GoogleFonts.inter(
              fontSize: 12, color: team1Color, fontWeight: FontWeight.w600))),
          const Icon(Icons.copy_rounded, size: 14, color: Colors.white24),
        ]),
      ),
    ),
  ]);
}

void _showShareDialog(BuildContext context, String matchId) {
  const base = 'https://padel-score-ab0b5.web.app';
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Del kamp', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _urlTile(context, 'TILSKUER-LINK', '$base/match/$matchId', Icons.visibility_rounded),
        const SizedBox(height: 14),
        _urlTile(context, 'TV-SKÆRM', '$base/tv/$matchId', Icons.tv_rounded),
        const SizedBox(height: 10),
        Text('Tryk for at kopiere', style: GoogleFonts.inter(fontSize: 11, color: Colors.white24)),
      ]),
      actions: [TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Luk', style: GoogleFonts.inter(color: Colors.white54)),
      )],
    ),
  );
}
