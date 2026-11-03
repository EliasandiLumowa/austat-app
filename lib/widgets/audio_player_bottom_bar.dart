import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class AudioPlayerBottomBar extends StatelessWidget {
  const AudioPlayerBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioService(),
      builder: (context, _) {
        final service = AudioService();
        final doc = service.currentDocument;

        if (!service.hasTrack || doc == null) {
          return const SizedBox.shrink();
        }

        final pos = service.position;
        final dur = service.duration;
        final progress = dur.inMilliseconds > 0
            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: AppTheme.gray200, width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thin scrubber bar at top of player
              SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.gray200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary600),
                ),
              ),

              InkWell(
                onTap: () => _showFullPlayerSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Track Cover
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 44,
                          height: 44,
                          color: AppTheme.primary50,
                          child: doc.coverUrl != null && doc.coverUrl!.isNotEmpty
                              ? Image.network(
                                  doc.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stack) => const Icon(
                                    Icons.audiotrack_rounded,
                                    color: AppTheme.primary600,
                                    size: 24,
                                  ),
                                )
                              : const Icon(
                                  Icons.audiotrack_rounded,
                                  color: AppTheme.primary600,
                                  size: 24,
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              doc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${service.formatDuration(pos)} / ${service.formatDuration(dur)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: AppTheme.gray500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    service.audioFormat,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Replay 10s
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded, size: 22, color: AppTheme.gray700),
                        tooltip: 'Mundur 10 detik',
                        onPressed: () => service.rewind10(),
                      ),

                      // Play/Pause circular button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary600,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            service.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => service.togglePlayPause(),
                        ),
                      ),

                      // Forward 10s
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded, size: 22, color: AppTheme.gray700),
                        tooltip: 'Maju 10 detik',
                        onPressed: () => service.forward10(),
                      ),

                      // Close player
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.gray400),
                        tooltip: 'Tutup pemutar',
                        onPressed: () => service.stop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showFullPlayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _FullAudioPlayerModal(),
    );
  }
}

class _FullAudioPlayerModal extends StatelessWidget {
  const _FullAudioPlayerModal();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioService(),
      builder: (context, _) {
        final service = AudioService();
        final doc = service.currentDocument;

        if (doc == null) {
          return const SizedBox.shrink();
        }

        final pos = service.position;
        final dur = service.duration;
        final maxDurMs = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
        final currentPosMs = pos.inMilliseconds.toDouble().clamp(0.0, maxDurMs);

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle drag bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.gray300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Header modal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'SEDANG DIPUTAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gray500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.audioFormat,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Large Album Art Cover
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.gray100,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: doc.coverUrl != null && doc.coverUrl!.isNotEmpty
                                ? Image.network(
                                    doc.coverUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stack) => const Center(
                                      child: Icon(Icons.library_books_rounded, size: 80, color: AppTheme.gray400),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.library_books_rounded, size: 80, color: AppTheme.gray400),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Document Title
                      Text(
                        doc.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Indicator & Year subtitle
                      Text(
                        '${doc.indicator?.name ?? 'Statistik'} • ${doc.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Progress Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.primary600,
                          inactiveTrackColor: AppTheme.gray200,
                          thumbColor: AppTheme.primary600,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: currentPosMs,
                          max: maxDurMs,
                          onChanged: (val) {
                            service.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),

                      // Time Display
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              service.formatDuration(pos),
                              style: const TextStyle(fontSize: 12, color: AppTheme.gray500, fontFamily: 'monospace'),
                            ),
                            Text(
                              service.formatDuration(dur),
                              style: const TextStyle(fontSize: 12, color: AppTheme.gray500, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Speed Button
                          InkWell(
                            onTap: () => service.cyclePlaybackRate(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.gray100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${service.playbackRate}x',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.gray700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Rewind 10s
                          IconButton(
                            iconSize: 32,
                            icon: const Icon(Icons.replay_10_rounded, color: AppTheme.gray800),
                            onPressed: () => service.rewind10(),
                          ),
                          const SizedBox(width: 14),

                          // Play/Pause Button
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primary600,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary600.withAlpha(90),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              iconSize: 36,
                              icon: Icon(
                                service.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => service.togglePlayPause(),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Forward 10s
                          IconButton(
                            iconSize: 32,
                            icon: const Icon(Icons.forward_10_rounded, color: AppTheme.gray800),
                            onPressed: () => service.forward10(),
                          ),
                          const SizedBox(width: 20),

                          // Stop Button
                          IconButton(
                            iconSize: 26,
                            icon: const Icon(Icons.stop_circle_outlined, color: AppTheme.gray500),
                            onPressed: () {
                              service.stop();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Text Transcript Preview if available
                      if (doc.extractedText != null && doc.extractedText!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.gray50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.gray200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.notes_rounded, size: 16, color: AppTheme.primary600),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ringkasan Audio',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.gray800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                doc.extractedText!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.gray700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
