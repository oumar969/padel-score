import 'package:web/web.dart' as web;

class AudioService {
  web.AudioContext? _ctx;

  /// Call on every user tap to keep AudioContext resumed (Safari/iOS).
  void unlock() {
    try {
      _ctx ??= web.AudioContext();
      _ctx!.resume();
    } catch (_) {}
  }

  void playCelebration() {
    try {
      final ctx = _ctx ?? web.AudioContext();
      _ctx = ctx;
      _note(ctx, 523.25, 0.00); // C5
      _note(ctx, 659.25, 0.15); // E5
      _note(ctx, 783.99, 0.30); // G5
      _note(ctx, 1046.5, 0.50); // C6
    } catch (_) {}
  }

  void _note(web.AudioContext ctx, double freq, double delay) {
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.type = 'sine';
    osc.frequency.value = freq;
    final t = ctx.currentTime + delay;
    gain.gain.setValueAtTime(0.28, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.28);
    osc.start(t);
    osc.stop(t + 0.32);
  }

  void dispose() {
    try { _ctx?.close(); } catch (_) {}
    _ctx = null;
  }
}
