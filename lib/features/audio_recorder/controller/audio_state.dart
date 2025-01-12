import 'dart:io';

class RecordingState {
  final bool isRecording;
  final bool isPlaying;
  final File? audioFile;
  final double? uploadProgress;
  final String? downloadUrl;

  RecordingState({
    this.isRecording = false,
    this.isPlaying = false,
    this.audioFile,
    this.uploadProgress,
    this.downloadUrl,
  });

  RecordingState copyWith({
    bool? isRecording,
    bool? isPlaying,
    File? audioFile,
    double? uploadProgress,
    String? downloadUrl,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      audioFile: audioFile ?? this.audioFile,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
