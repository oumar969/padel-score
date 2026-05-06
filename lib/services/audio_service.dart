import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playCelebration() async {
    try {
      final wav = _buildCelebrationWav();
      await _player.play(BytesSource(wav));
    } catch (_) {
      // Audio failures are non-critical
    }
  }

  void dispose() => _player.dispose();

  /// Generates a C5–E5–G5–C6 arpeggio as 16-bit mono PCM WAV bytes.
  Uint8List _buildCelebrationWav() {
    const sampleRate = 22050;
    const noteDuration = 0.13; // seconds per note
    const noteFadeRatio = 0.3; // fade-out portion of each note
    final freqs = [523.25, 659.25, 783.99, 1046.50]; // C5 E5 G5 C6

    final samplesPerNote = (sampleRate * noteDuration).round();
    final totalSamples = samplesPerNote * freqs.length;
    final samples = Int16List(totalSamples);

    for (var n = 0; n < freqs.length; n++) {
      final freq = freqs[n];
      final base = n * samplesPerNote;
      for (var i = 0; i < samplesPerNote; i++) {
        final t = i / sampleRate;
        final progress = i / samplesPerNote;
        final envelope = progress < (1 - noteFadeRatio)
            ? 1.0
            : (1.0 - progress) / noteFadeRatio;
        final value = (32767 * 0.55 * envelope * sin(2 * pi * freq * t)).round();
        samples[base + i] = value.clamp(-32767, 32767);
      }
    }

    return _encodeWav(samples, sampleRate);
  }

  Uint8List _encodeWav(Int16List samples, int sampleRate) {
    const channels = 1;
    const bitsPerSample = 16;
    final dataBytes = samples.length * 2;
    final buf = ByteData(44 + dataBytes);

    // RIFF chunk
    buf
      ..setUint8(0, 0x52) ..setUint8(1, 0x49) ..setUint8(2, 0x46) ..setUint8(3, 0x46)
      ..setUint32(4, 36 + dataBytes, Endian.little)
      ..setUint8(8, 0x57) ..setUint8(9, 0x41) ..setUint8(10, 0x56) ..setUint8(11, 0x45);

    // fmt chunk
    buf
      ..setUint8(12, 0x66) ..setUint8(13, 0x6D) ..setUint8(14, 0x74) ..setUint8(15, 0x20)
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, channels, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * channels * bitsPerSample ~/ 8, Endian.little)
      ..setUint16(32, channels * bitsPerSample ~/ 8, Endian.little)
      ..setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    buf
      ..setUint8(36, 0x64) ..setUint8(37, 0x61) ..setUint8(38, 0x74) ..setUint8(39, 0x61)
      ..setUint32(40, dataBytes, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      buf.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buf.buffer.asUint8List();
  }
}
