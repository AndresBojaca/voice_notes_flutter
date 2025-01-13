import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'audio_state.dart';

final recordingStateProvider =
    StateNotifierProvider<AudioController, RecordingState>((ref) {
  return AudioController();
});

class AudioController extends StateNotifier<RecordingState> {
  final RecorderController recorderController = RecorderController();
  final PlayerController playerController = PlayerController();
  Timer? _timer;
  int _secondsElapsed = 0;

  UploadTask? uploadTask;

  String? _filePath;

  AudioController() : super(RecordingState()) {
    // Cuando se completa la reproducción, establecer isPlaying en false
    playerController.onCompletion.listen((_) {
    });
  }

  Future<String> _getFilePath() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    _filePath = path.join(appDocumentsDir.path, 'voice_note.wav');
    return _filePath!;
  }

  Future<void> startRecording() async {
    final filePath = await _getFilePath();
    if (await recorderController.hasPermission) {
      state = state.copyWith(isRecording: true, recordingDuration: "00:00");
      // Inicia el temporizador
      _secondsElapsed = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _secondsElapsed++;
        final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
        final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
        state = state.copyWith(recordingDuration: "$minutes:$seconds");
      });

      recorderController.reset();
      recorderController.record(path: filePath);

      state = state.copyWith(isRecording: true);
    }
  }

  Future<void> stopRecording() async {
    _timer?.cancel();
    final filePath = await recorderController.stop();
    if (filePath != null) {
      final file = File(filePath);
      state = state.copyWith(isRecording: false, audioFile: file);
    }
  }

  Future<void> playLocalAudio() async {

    final fileLengthInDuration = await playerController.getDuration(DurationType.max);
    final currentDuration = await playerController.getDuration(DurationType.current);

    if (state.audioFile == null) return;
    playerController.stopPlayer();
    state = state.copyWith(audioFile: File(_filePath!));
    await playerController.preparePlayer(
      path: _filePath!,
    );
    playerController.startPlayer();
    state = state.copyWith(isPlaying: true, isRecording: true, recordingDuration: "${currentDuration} / ${fileLengthInDuration}");
  }


  Future<void> stopLocalAudio() async {
    await playerController.stopPlayer();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> pauseLocalAudio() async {
    await playerController.pausePlayer();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> uploadAudio() async {
    try {
      if (state.audioFile == null) return;

      final fileName = 'voice_note_${DateTime.now()}.wav';

      Reference storageRef =
          FirebaseStorage.instance.ref().child('voice_notes').child(fileName);

      File file = File(_filePath.toString()!);
      uploadTask = storageRef.putFile(file);

      uploadTask!.snapshotEvents.listen((event) {
        final totalBytes = event.totalBytes;
        final bytesTransferred = event.bytesTransferred;
        final currentProgress = bytesTransferred / totalBytes;
        print('Progreso de carga: $currentProgress');
        state = state.copyWith(uploadProgress: currentProgress);

        //Despues de completar la carga y 1.5s, restablecer el progreso
        if (state.uploadProgress == 1.0) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            state = state.copyWith(uploadProgress: 0);
          });
        }
      });

      final snapshot = await uploadTask!.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      state = state.copyWith(downloadUrl: downloadUrl, uploadProgress: null);
    } on firebase_core.FirebaseException catch (e) {
      print('Código de error: ${e.code}');
      print('Mensaje de error: ${e.message}');
    } catch (e) {
      print('Error inesperado: $e');
    }
  }

  // Future<void> playAudio() async {
  //   if (state.downloadUrl == null) return;
  //   await _player.setUrl(state.downloadUrl!);
  //   _player.play();
  //   state = state.copyWith(isPlaying: true);
  // }

  Future<void> stopAudio() async {
    state = state.copyWith(isPlaying: false);
  }

  @override
  void dispose() {
    recorderController.dispose();
    playerController.dispose();
    super.dispose();
  }
}

final audioControllerProvider =
    StateNotifierProvider<AudioController, RecordingState>((ref) {
  return AudioController();
});
