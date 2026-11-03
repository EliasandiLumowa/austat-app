import 'package:flutter/material.dart';
import '../services/voice_assistant_service.dart';
import '../models/indicator_model.dart';
import '../theme/app_theme.dart';

class VoiceAccessibilityWidget extends StatefulWidget {
  final VoidCallback? onIndicatorTap;

  const VoiceAccessibilityWidget({super.key, this.onIndicatorTap});

  @override
  State<VoiceAccessibilityWidget> createState() => _VoiceAccessibilityWidgetState();
}

class _VoiceAccessibilityWidgetState extends State<VoiceAccessibilityWidget>
    with SingleTickerProviderStateMixin {
  final VoiceAssistantService _voice = VoiceAssistantService();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _voice.addListener(_onVoiceUpdate);
  }

  void _onVoiceUpdate() {
    if (!mounted) return;
    if (_voice.isListening) {
      if (!_animController.isAnimating) {
        _animController.repeat(reverse: true);
      }
    } else {
      _animController.stop();
      _animController.reset();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _voice.removeListener(_onVoiceUpdate);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _voice.isListening;
    final isSpeaking = _voice.isSpeaking;
    final lastWords = _voice.lastSpokenWords;
    final selectedIndicator = _voice.selectedIndicator;

    Color bannerColor;
    Color iconBgColor;
    IconData statusIcon;
    String statusTitle;

    if (isListening) {
      bannerColor = const Color(0xFF1E3A8A); // Deep blue
      iconBgColor = const Color(0xFFEF4444); // Red pulsing mic
      statusIcon = Icons.mic_rounded;
      statusTitle = 'Mendengarkan... Silakan Bicara';
    } else if (isSpeaking) {
      bannerColor = const Color(0xFF1E293B); // Dark slate
      iconBgColor = AppTheme.primary600;
      statusIcon = Icons.volume_up_rounded;
      statusTitle = 'Asisten Sedang Berbicara...';
    } else if (_voice.state == VoiceState.processing) {
      bannerColor = const Color(0xFF312E81);
      iconBgColor = const Color(0xFF8B5CF6);
      statusIcon = Icons.hourglass_top_rounded;
      statusTitle = 'Memproses Suara Anda...';
    } else {
      bannerColor = const Color(0xFF1E293B);
      iconBgColor = AppTheme.primary600;
      statusIcon = Icons.mic_none_rounded;
      statusTitle = 'Kendali Suara Aktif';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Ketuk di mana saja untuk interupsi dan langsung bicara
            _voice.userInterruptedToSpeak();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar (Status & Pulsing Mic)
                Row(
                  children: [
                    ScaleTransition(
                      scale: isListening ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isListening)
                              BoxShadow(
                                color: Colors.red.withAlpha(120),
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                          ],
                        ),
                        child: Icon(statusIcon, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                statusTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isListening) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _voice.statusMessage,
                            style: TextStyle(
                              color: Colors.white.withAlpha(190),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Quick Action: Ulangi Panduan Suara
                    IconButton(
                      icon: const Icon(Icons.replay_rounded, color: Colors.white70),
                      tooltip: 'Ulangi Panduan Suara',
                      onPressed: () => _voice.startWelcomeFlow(),
                    ),
                  ],
                ),

                // Box Kata Yang Diucapkan (Speech Recognition Feedback)
                if (lastWords.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.record_voice_over_rounded, color: Color(0xFF60A5FA), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Anda mengucapkan: "$lastWords"',
                            style: const TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Indikator Terpilih Saat Ini
                if (selectedIndicator != null) ...[
                  const SizedBox(height: 12),
                  _buildMatchedIndicatorCard(selectedIndicator),
                ],

                const SizedBox(height: 8),
                Text(
                  isListening
                      ? (_voice.matchedDocuments.isNotEmpty
                          ? '• Sebutkan nomor file (contoh: "File 1") atau judul file untuk memutar'
                          : '• Sebutkan nomor (1-12) atau nama indikator langsung')
                      : '• Ketuk layar atau katakan "Ulangi" / "Bantuan" kapan saja',
                  style: TextStyle(
                    color: Colors.white.withAlpha(170),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchedIndicatorCard(IndicatorModel indicator) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withAlpha(40),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3B82F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
              const SizedBox(width: 8),
              Text(
                'Indikator Aktif: ${indicator.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (indicator.description != null && indicator.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              indicator.description!,
              style: TextStyle(
                color: Colors.white.withAlpha(210),
                fontSize: 12,
              ),
            ),
          ],
          if (_voice.matchedDocuments.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${_voice.matchedDocuments.length} dokumen statistik tersedia. Dokumen terbaru: "${_voice.matchedDocuments.first.title}"',
              style: const TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

