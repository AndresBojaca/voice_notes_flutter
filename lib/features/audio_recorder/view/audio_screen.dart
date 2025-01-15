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
                    enableSeekGesture: true,
                    continuousWaveform: true,
                    size: Size(MediaQuery.of(context).size.width, 100),
                    playerController: audioController.playerController,
                    playerWaveStyle: const PlayerWaveStyle(
                      liveWaveColor: Colors.deepPurple,
                      showSeekLine: false,
                      fixedWaveColor: Colors.grey,
                      scaleFactor: 200.0,
                    ),
                    padding: const EdgeInsets.only(left: 18),
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                  )
                : AudioWaveforms(
                    enableGesture: true,
                    size: Size(MediaQuery.of(context).size.width, 100),
                    recorderController: audioController.recorderController,
                    waveStyle: const WaveStyle(
                      waveColor: Colors.redAccent,
                      showMiddleLine: false,
                      extendWaveform: true,
                      scaleFactor: 180.0,
                      spacing: 5,
                      showTop: true,
                      showBottom: true,
                    ),
                    padding: const EdgeInsets.only(left: 18),
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    shouldCalculateScrolledPosition: true,
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
                            : () => audioController.uploadAudio(context),
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
                    onPressed: audioState.isPlaying == true
                        ? null
                        : audioState.isRecording
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
                const SizedBox(width: 16),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () async {
                      final audioController =
                          ref.read(audioControllerProvider.notifier);

                      // Obtén la lista de grabaciones
                      final List<String> audioFiles =
                          await audioController.fetchAudioFiles();

                      if (context.mounted) {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return audioFiles.isNotEmpty
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Text('Grabaciones disponibles'),
                                          SizedBox(height: 16),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: audioFiles.length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  leading: const Icon(Icons.audiotrack),
                                                  title: Text(
                                                    audioFiles[0],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                          'No hay grabaciones disponibles'),
                                    ),
                                  );
                          },
                        );
                      }
                    },
                    child: const Icon(
                      Icons.list,
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
