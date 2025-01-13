import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../audio_recorder/controller/audio_controller.dart';

class AudioScreen extends ConsumerWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioControllerProvider);
    final audioController = ref.read(audioControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Notes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Visualizador de audio
            audioState.isPlaying
                ? AudioFileWaveforms(
                    size: Size(MediaQuery.of(context).size.width, 100),
                    playerController: audioController.playerController,
                    playerWaveStyle: const PlayerWaveStyle(
                      liveWaveColor: Colors.redAccent,
                      showSeekLine: false,
                      fixedWaveColor: Colors.grey,
                    ),
                    padding: const EdgeInsets.only(left: 18),
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                  )
                : AudioWaveforms(
                    enableGesture: false,
                    size: Size(MediaQuery.of(context).size.width, 100),
                    recorderController: audioController.recorderController,
                    waveStyle: const WaveStyle(
                      waveColor: Colors.redAccent,
                      extendWaveform: true,
                      showMiddleLine: false,
                    ),
                    padding: const EdgeInsets.only(left: 18),
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                  ),
            // Temporizador de Grabación
            Text(
              audioState.recordingDuration,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Botones en una fila
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón de subida

                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progreso Circular
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: audioState.uploadProgress ?? 0,
                        strokeWidth: 8.0,
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.deepPurple),
                      ),
                    ),
                    // Botón
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: audioState.audioFile == null ||
                                audioState.isRecording == true
                            ? null
                            : audioController.uploadAudio,
                        child: const Icon(Icons.cloud_upload, size: 28),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Botón de grabación
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: audioState.isRecording
                        ? audioController.stopRecording
                        : audioController.startRecording,
                    child: Icon(
                      audioState.isRecording ? Icons.stop : Icons.circle,
                      size: 28,
                      color: audioState.isRecording
                          ? Colors.deepPurple
                          : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Botón de reproducción
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: audioState.audioFile == null ||
                            audioState.isRecording == true
                        ? null
                        : audioState.isPlaying
                            ? audioController.pauseLocalAudio
                            : audioController.playLocalAudio,
                    child: Icon(
                      audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
