import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/document_model.dart';

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _initPlayer();
  }

  final AudioPlayer _player = AudioPlayer();

  DocumentModel? _currentDocument;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackRate = 1.0;
  double _volume = 1.0;
  String _audioFormat = 'MP3';

  DocumentModel? get currentDocument => _currentDocument;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get hasTrack => _currentDocument != null;
  Duration get position => _position;
  Duration get duration => _duration;
  double get playbackRate => _playbackRate;
  double get volume => _volume;
  String get audioFormat => _audioFormat;

  void _initPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      _isLoading = false;
      notifyListeners();
    });

    _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  Future<void> playDocument(DocumentModel document, {String format = 'MP3'}) async {
    // Matikan TTS apapun seketika agar tidak bertabrakan dengan audio dokumen
    try {
      await FlutterTts().stop();
    } catch (_) {}

    _currentDocument = document;
    _audioFormat = format;
    _isLoading = true;
    _position = Duration.zero;

    // Use document's estimated duration if known
    if (document.audioDuration > 0) {
      _duration = Duration(seconds: document.audioDuration);
    }

    notifyListeners();

    try {
      final url = (format.toUpperCase() == 'FLAC' && document.flacUrl != null)
          ? document.flacUrl!
          : (document.mp3Url ?? '');

      if (url.isNotEmpty) {
        await _player.setPlaybackRate(_playbackRate);
        await _player.setVolume(_volume);
        await _player.play(UrlSource(url));
      } else {
        // Fallback simulation when offline
        _isPlaying = true;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // In case network or URL is simulated
      _isLoading = false;
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (_isPlaying) {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (!_isPlaying && _currentDocument != null) {
      await _player.resume();
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async {
    _position = position;
    await _player.seek(position);
    notifyListeners();
  }

  Future<void> rewind10() async {
    final newPos = _position - const Duration(seconds: 10);
    final target = newPos < Duration.zero ? Duration.zero : newPos;
    await seek(target);
  }

  Future<void> forward10() async {
    final newPos = _position + const Duration(seconds: 10);
    final target = _duration > Duration.zero && newPos > _duration ? _duration : newPos;
    await seek(target);
  }

  Future<void> cyclePlaybackRate() async {
    final rates = [1.0, 1.25, 1.5, 2.0];
    final nextIndex = (rates.indexOf(_playbackRate) + 1) % rates.length;
    _playbackRate = rates[nextIndex];
    await _player.setPlaybackRate(_playbackRate);
    notifyListeners();
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentDocument = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
