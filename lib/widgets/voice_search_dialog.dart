import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class VoiceSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic> parsed)? onSearchParsed;

  const VoiceSearchDialog({super.key, this.onSearchParsed});

  static Future<void> show(BuildContext context, {Function(Map<String, dynamic> parsed)? onSearchParsed}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => VoiceSearchDialog(onSearchParsed: onSearchParsed),
    );
  }

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _textController = TextEditingController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _statusMessage = 'Menyiapkan mikrofon...';
  String _localeId = 'id_ID';

  final List<String> _suggestedVoicePhrases = [
    'Pertumbuhan ekonomi 2024',
    'Inflasi Sulawesi Utara',
    'Publikasi keadaan ketenagakerjaan',
    'BRS kemiskinan',
    'Nilai tukar petani 2025',
    'Statistik pariwisata',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!mounted) return;

      setState(() {
        _speechEnabled = available;
        if (available) {
          _statusMessage = 'Mendengarkan... Silakan berbicara';
        } else {
          _statusMessage = 'Izin mikrofon tidak aktif atau tidak didukung';
        }
      });

      if (available) {
        // Detect Indonesian locale if supported
        final locales = await _speech.locales();
        final indLocale = locales.where(
          (l) => l.localeId.toLowerCase().startsWith('id'),
        );
        if (indLocale.isNotEmpty) {
          _localeId = indLocale.first.localeId;
        } else {
          final system = await _speech.systemLocale();
          if (system != null) {
            _localeId = system.localeId;
          }
        }

        _startListening();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _speechEnabled = false;
        _statusMessage = 'Gagal mengakses mikrofon: $e';
      });
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) return;
    await _speech.stop();
    setState(() {
      _isListening = true;
      _statusMessage = 'Mendengarkan... Silakan berbicara';
    });
    _pulseController.repeat(reverse: true);

    final listenOptions = stt.SpeechListenOptions(
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      cancelOnError: false,
    );

    // ignore: deprecated_member_use
    await _speech.listen(
      onResult: _onSpeechResult,
      // ignore: deprecated_member_use
      localeId: _localeId,
      listenOptions: listenOptions,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _statusMessage = _textController.text.isNotEmpty
          ? 'Selesai mendengarkan'
          : 'Ketuk mikrofon untuk mulai berbicara';
    });
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      setState(() {
        _isListening = true;
        _statusMessage = 'Mendengarkan... Silakan berbicara';
      });
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else if (status == 'notListening' || status == 'done') {
      setState(() {
        _isListening = false;
        _statusMessage = _textController.text.isNotEmpty
            ? 'Selesai mendengarkan'
            : 'Ketuk mikrofon untuk mulai berbicara';
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _statusMessage = 'Gagal mengenali suara: ${error.errorMsg}';
    });
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _textController.text = result.recognizedWords;
    });

    // Auto submit if speech recognition finalized speech with text
    if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      _submitVoiceQuery(result.recognizedWords.trim());
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _submitVoiceQuery(String phrase) async {
    _speech.stop();
    final parsed = await ApiService().parseVoiceSearch(phrase);
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.onSearchParsed != null) {
      widget.onSearchParsed!(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mic_rounded, color: AppTheme.primary600, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pencarian Suara',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.gray500),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pulsing Glowing Microphone (Tap to toggle)
            GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final scale = _isListening ? _pulseAnimation.value : 1.0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      if (_isListening)
                        Container(
                          width: 90 * scale,
                          height: 90 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary600.withAlpha((40 / scale).toInt()),
                          ),
                        ),
                      // Inner glowing circle
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                                : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? AppTheme.primary600 : Colors.black26).withAlpha(120),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Status Text
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _isListening ? AppTheme.primary700 : AppTheme.gray800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isListening
                  ? 'Katakan kata kunci atau indikator statistik...'
                  : 'Ketuk ikon mikrofon di atas untuk berbicara.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.gray500, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Direct voice text input & preview
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Hasil suara atau ketik manual...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.primary600, size: 20),
                  onPressed: () {
                    if (_textController.text.trim().isNotEmpty) {
                      _submitVoiceQuery(_textController.text.trim());
                    }
                  },
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _submitVoiceQuery(val.trim());
                }
              },
            ),
            const SizedBox(height: 16),

            // Suggested Voice Commands Chips
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Contoh Perintah Suara:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray600,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedVoicePhrases.map((phrase) {
                return InkWell(
                  onTap: () => _submitVoiceQuery(phrase),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up_outlined, size: 12, color: AppTheme.primary700),
                        const SizedBox(width: 4),
                        Text(
                          phrase,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
