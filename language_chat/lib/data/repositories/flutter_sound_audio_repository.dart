import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:language_chat/domain/repositories/audio_repository.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class FlutterSoundAudioRepository implements AudioRepository {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;

  Future<void> init() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    try {
      await _recorder!.openRecorder();
      _isRecorderInitialized = true;
    } catch (e) {
      print('Error initializing recorder: $e');
    }

    try {
      await _player!.openPlayer();
      _isPlayerInitialized = true;
    } catch (e) {
      print('Error initializing player: $e');
    }
  }

  Future<void> dispose() async {
    try {
      if (_isRecorderInitialized) {
        await _recorder?.closeRecorder();
        _isRecorderInitialized = false;
      }
    } catch (e) {
      print('Error closing recorder: $e');
    }

    try {
      if (_isPlayerInitialized) {
        await _player?.closePlayer();
        _isPlayerInitialized = false;
      }
    } catch (e) {
      print('Error closing player: $e');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();

    // Para Android 13+ não precisamos mais da permissão de storage
    if (Platform.isAndroid) {
      final androidInfo = await Permission.storage.status;
      return microphoneStatus.isGranted;
    }

    // Para iOS
    return microphoneStatus.isGranted;
  }

  @override
  Future<void> startRecording(String filePath) async {
    if (!_isRecorderInitialized) {
      throw Exception('Recorder not initialized');
    }

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw Exception('Permissions not granted');
    }

    // Criar diretório se não existir
    final file = File(filePath);
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    await _recorder!.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS, // Mudança: usar aacADTS ao invés de aacMP4
    );
  }

  @override
  Future<String?> stopRecording() async {
    if (!_isRecorderInitialized || !(_recorder?.isRecording ?? false)) {
      return null;
    }

    return await _recorder!.stopRecorder();
  }

  @override
  Future<void> playAudio(String filePath) async {
    if (!_isPlayerInitialized) {
      throw Exception('Player not initialized');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Audio file not found: $filePath');
    }

    await _player!.startPlayer(fromURI: filePath);
  }

  @override
  Future<void> stopAudio() async {
    if (!_isPlayerInitialized) return;

    if (_player?.isPlaying ?? false) {
      await _player!.stopPlayer();
    }
  }

  @override
  Future<Duration> getAudioDuration(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return Duration.zero;
    }

    // Para obter a duração real, você precisaria de uma biblioteca adicional
    // Por enquanto, vamos fazer uma estimativa baseada no tamanho do arquivo
    final fileSize = await file.length();

    // Estimativa rough: ~16KB por segundo para AAC
    final estimatedSeconds = (fileSize / 16000).round().clamp(1, 300);

    return Duration(seconds: estimatedSeconds);
  }

  @override
  Stream<Duration> getPlaybackPosition() {
    if (!_isPlayerInitialized || _player == null) {
      return Stream.value(Duration.zero);
    }

    return _player!.onProgress?.map((e) => e.position) ??
        Stream.value(Duration.zero);
  }

  @override
  Stream<bool> getRecordingState() {
    if (!_isRecorderInitialized || _recorder == null) {
      return Stream.value(false);
    }

    return Stream.periodic(
      const Duration(milliseconds: 100),
    ).map((_) => _recorder?.isRecording ?? false);
  }

  @override
  Stream<bool> getPlayingState() {
    if (!_isPlayerInitialized || _player == null) {
      return Stream.value(false);
    }

    return Stream.periodic(
      const Duration(milliseconds: 100),
    ).map((_) => _player?.isPlaying ?? false);
  }

  // Método helper para gerar path de arquivo único
  Future<String> _generateUniqueFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/audio_$timestamp.aac';
  }
}
