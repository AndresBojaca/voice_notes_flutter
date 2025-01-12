import 'dart:io';

class RecordingState {
  final bool isRecording;
  final File? audioFile;
  final double? uploadProgress;
  final String? downloadUrl;

  RecordingState({
    this.isRecording = false,
    this.audioFile,
    this.uploadProgress,
    this.downloadUrl,
  });

  RecordingState copyWith({
    bool? isRecording,
    File? audioFile,
    double? uploadProgress,
    String? downloadUrl,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      audioFile: audioFile ?? this.audioFile,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
