import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_visualizer.dart';
import '../../audio_recorder/controller/audio_controller.dart';

class AudioScreen extends ConsumerWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioControllerProvider);
    final audioController = ref.read(audioControllerProvider.notifier);
    final controller = ref.read(recordingStateProvider.notifier);

return Scaffold(
      appBar: AppBar(title: Text('Voice Notes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
              ),
              onPressed: audioState.isRecording ?audioController.stopRecording :audioController.startRecording,
              child: Icon(audioState.isRecording ? Icons.stop : Icons.mic, size: 40),
            ),
            SizedBox(height: 16),
            if (audioState.isRecording) AudioVisualizer(recorderController: controller.recorderController),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
              ),
              onPressed: audioState.audioFile == null ? null : audioController.playLocalAudio,
              child: Icon(Icons.play_arrow, size: 40),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
              ),
              onPressed: audioState.audioFile == null ? null : audioController.uploadAudio,
              child: Icon(Icons.cloud_upload, size: 40),
            ),
            SizedBox(height: 16),
            audioState.uploadProgress != null
                ? LinearProgressIndicator(value: audioState.uploadProgress)
                : SizedBox.shrink(),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
              ),
              onPressed: audioState.downloadUrl == null ? null : audioController.playAudio,
              child: Icon(Icons.cloud_download, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}
