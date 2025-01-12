import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'audio_state.dart';

final recordingStateProvider =
    StateNotifierProvider<AudioController, RecordingState>((ref) {
  return AudioController();
});

class AudioController extends StateNotifier<RecordingState> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final RecorderController recorderController = RecorderController();
  UploadTask? uploadTask;

  String? _filePath;

  AudioController() : super(RecordingState()) {
    // Escucha los cambios en el estado del reproductor
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing &&
          playerState.processingState == ProcessingState.ready;
      final isCompleted =
          playerState.processingState == ProcessingState.completed;

      if (isCompleted) {
        _player.stop(); // Reiniciar al detenerse automáticamente
        state = state.copyWith(isPlaying: false);
      } else {
        state = state.copyWith(isPlaying: isPlaying);
      }
    });
  }

  Future<String> _getFilePath() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    _filePath = path.join(appDocumentsDir.path, 'voice_note.wav');
    return _filePath!;
  }

  Future<void> startRecording() async {
    final filePath = await _getFilePath();
    if (await _recorder.hasPermission()) {
      recorderController.reset();
      await _recorder.start(const RecordConfig(), path: filePath);
      state = state.copyWith(isRecording: true);
    }
  }

  Future<void> stopRecording() async {
    recorderController.stop();
    final filePath = await _recorder.stop();
    print('File path STOOPPP: $_filePath');
    if (filePath != null) {
      final file = File(filePath);
      state = state.copyWith(isRecording: false, audioFile: file);
    }
  }

  Future<void> playLocalAudio() async {
    if (state.audioFile == null) return;
    state = state.copyWith(audioFile: File(_filePath!));
    await _player.setFilePath(_filePath!);
    await _player.play();
    state = state.copyWith(isPlaying: true);
  }

  Future<void> togglePlayPause() async {
    if (state.audioFile == null) return;
    if (_player.playing) {
      await stopLocalAudio();
    } else {
      await playLocalAudio();
    }
  }

  Future<void> stopLocalAudio() async {
    await _player.stop();
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
        if(state.uploadProgress == 1.0) {
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

  Future<void> playAudio() async {
    if (state.downloadUrl == null) return;
    await _player.setUrl(state.downloadUrl!);
    _player.play();
    state = state.copyWith(isPlaying: true);
  }

  Future<void> stopAudio() async {
    await _player.stop();
    state = state.copyWith(isPlaying: false);
  }
}

final audioControllerProvider =
    StateNotifierProvider<AudioController, RecordingState>((ref) {
  return AudioController();
});
