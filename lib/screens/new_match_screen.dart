import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';
import '../providers/match_provider.dart';

class NewMatchScreen extends ConsumerStatefulWidget {
  const NewMatchScreen({super.key});

  @override
  ConsumerState<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends ConsumerState<NewMatchScreen> {
  final _t1 = TextEditingController(text: 'Hold 1');
  final _t2 = TextEditingController(text: 'Hold 2');
  final _focus1 = FocusNode();
  final _focus2 = FocusNode();
  bool _loading = false;

  @override
  void dispose() {
    _t1.dispose();
    _t2.dispose();
    _focus1.dispose();
    _focus2.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_t1.text.trim().isEmpty || _t2.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final id = await ref.read(matchActionsProvider).createMatch(_t1.text, _t2.text);
      if (mounted) context.replace('/match/$id');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: $e'),
            backgroundColor: team2Color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ny kamp',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              _TeamInput(
                controller: _t1,
                focusNode: _focus1,
                label: 'Hold 1',
                hint: 'Navn på venstre hold',
                color: team1Color,
                onSubmitted: (_) => _focus2.requestFocus(),
              ),

              const SizedBox(height: 16),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    'VS',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _TeamInput(
                controller: _t2,
                focusNode: _focus2,
                label: 'Hold 2',
                hint: 'Navn på højre hold',
                color: team2Color,
                onSubmitted: (_) => _start(),
              ),

              const Spacer(),

              _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: team1Color),
                    )
                  : ElevatedButton(
                      onPressed: _start,
                      child: const Text('Start kamp'),
                    ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final Color color;
  final ValueChanged<String> onSubmitted;

  const _TeamInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.color,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          onSubmitted: onSubmitted,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 18,
              color: Colors.white24,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
