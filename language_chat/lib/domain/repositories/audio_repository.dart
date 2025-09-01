abstract class AudioRepository {
  Future<bool> requestPermissions();
  Future<void> startRecording(String filePath);
  Future<String?> stopRecording();
  Future<void> playAudio(String filePath);
  Future<void> stopAudio();
  Future<Duration> getAudioDuration(String filePath);
  Stream<Duration> getPlaybackPosition();
  Stream<bool> getRecordingState();
  Stream<bool> getPlayingState();
}
