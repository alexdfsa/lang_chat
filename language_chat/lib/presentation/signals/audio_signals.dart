import 'dart:async';

import 'package:langchat/domain/repositories/audio_repository.dart';
import 'package:signals/signals.dart';

class AudioSignals {
  final AudioRepository _audioRepository;

  AudioSignals({required AudioRepository audioRepository})
    : _audioRepository = audioRepository;

  // Signals
  final _isRecording = signal<bool>(false);
  final _isPlaying = signal<bool>(false);
  final _recordingPath = signal<String?>(null);
  final _recordingDuration = signal<Duration>(Duration.zero);
  final _playbackPosition = signal<Duration>(Duration.zero);
  final _hasPermissions = signal<bool>(false);
  final _error = signal<String?>(null);

  Timer? _recordingTimer;

  // Getters
  ReadonlySignal<bool> get isRecording => _isRecording.readonly();
  ReadonlySignal<bool> get isPlaying => _isPlaying.readonly();
  ReadonlySignal<String?> get recordingPath => _recordingPath.readonly();
  ReadonlySignal<Duration> get recordingDuration =>
      _recordingDuration.readonly();
  ReadonlySignal<Duration> get playbackPosition => _playbackPosition.readonly();
  ReadonlySignal<bool> get hasPermissions => _hasPermissions.readonly();
  ReadonlySignal<String?> get error => _error.readonly();

  // Computed
  late final ReadonlySignal<bool> canRecord = computed(
    () => _hasPermissions.value && !_isRecording.value && !_isPlaying.value,
  );

  late final ReadonlySignal<bool> canPlay = computed(
    () => _recordingPath.value != null && !_isRecording.value,
  );

  // Actions
  Future<void> requestPermissions() async {
    try {
      final granted = await _audioRepository.requestPermissions();
      _hasPermissions.value = granted;

      if (!granted) {
        _error.value = 'Permissões de áudio necessárias para gravação';
      }
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<void> startRecording([String? customPath]) async {
    if (!_hasPermissions.value) {
      await requestPermissions();
      if (!_hasPermissions.value) return;
    }

    try {
      String filePath;
      if (customPath != null) {
        filePath = customPath;
      } else {
        // Gerar um path padrão
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '/tmp/audio_$timestamp.aac';
      }

      await _audioRepository.startRecording(filePath);
      _isRecording.value = true;
      _recordingPath.value = filePath;
      _error.value = null;

      // Start duration tracking
      _trackRecordingDuration();
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording.value) return null;

    try {
      final filePath = await _audioRepository.stopRecording();
      _recordingTimer?.cancel();
      _isRecording.value = false;

      return filePath;
    } catch (e) {
      _error.value = e.toString();
      return null;
    }
  }

  Future<void> playAudio(String filePath) async {
    if (_isPlaying.value) {
      await stopAudio();
    }

    try {
      await _audioRepository.playAudio(filePath);
      _isPlaying.value = true;
      _error.value = null;

      // Track playback position
      _trackPlaybackPosition();
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<void> stopAudio() async {
    try {
      await _audioRepository.stopAudio();
      _isPlaying.value = false;
      _playbackPosition.value = Duration.zero;
    } catch (e) {
      _error.value = e.toString();
    }
  }

  void _trackRecordingDuration() {
    _recordingTimer?.cancel();
    _recordingDuration.value = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording.value) {
        timer.cancel();
      } else {
        _recordingDuration.value = Duration(
          seconds: _recordingDuration.value.inSeconds + 1,
        );
      }
    });
  }

  void _trackPlaybackPosition() {
    _audioRepository.getPlayingState().listen((playing) {
      _isPlaying.value = playing;
      if (!playing) {
        _playbackPosition.value = Duration.zero;
      }
    });

    _audioRepository.getPlaybackPosition().listen((position) {
      if (_isPlaying.value) {
        _playbackPosition.value = position;
      }
    });
  }

  void clearError() {
    _error.value = null;
  }

  void reset() {
    _recordingTimer?.cancel();
    _isRecording.value = false;
    _isPlaying.value = false;
    _recordingPath.value = null;
    _recordingDuration.value = Duration.zero;
    _playbackPosition.value = Duration.zero;
    _error.value = null;
  }
}
