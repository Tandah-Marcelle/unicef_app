import 'package:audioplayers/audioplayers.dart';

/// Audio playback service (singleton).
/// Recording requires the `record` package which needs Gradle 8.12+.
/// On-device recording is currently stubbed — facilitators use text notes.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  String? _currentPath;

  PlayerState _state = PlayerState.stopped;
  PlayerState get playerState => _state;
  String?     get currentPath => _currentPath;

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration>    get onPositionChanged     => _player.onPositionChanged;
  Stream<Duration?>   get onDurationChanged     => _player.onDurationChanged;

  bool get isPlaying => _state == PlayerState.playing;

  Future<void> play(String filePath) async {
    try {
      _currentPath = filePath;
      await _player.play(DeviceFileSource(filePath));
      _state = PlayerState.playing;
    } catch (_) {}
  }

  Future<void> pause() async {
    try { await _player.pause(); _state = PlayerState.paused; } catch (_) {}
  }

  Future<void> resume() async {
    try { await _player.resume(); _state = PlayerState.playing; } catch (_) {}
  }

  Future<void> stop() async {
    try { await _player.stop(); _state = PlayerState.stopped; _currentPath = null; } catch (_) {}
  }

  void dispose() => _player.dispose();
}
