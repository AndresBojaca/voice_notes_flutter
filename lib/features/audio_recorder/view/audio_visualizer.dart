import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class AudioVisualizer extends StatelessWidget {
  final RecorderController recorderController;

  AudioVisualizer({required this.recorderController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey[300],
      child: AudioWaveforms(
        enableGesture: false,
        size: Size(double.infinity, 100),
        recorderController: recorderController,
        waveStyle: const WaveStyle(
          waveColor: Colors.blue,
          extendWaveform: true,
          showMiddleLine: false,
        ),
      ),
    );
  }
}
