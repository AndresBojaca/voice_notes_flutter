import 'dart:io';

import 'package:flutter/material.dart';
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

  UploadTask? uploadTask;

  String? _filePath;

  AudioController() : super(RecordingState()) {
    // Comprueba si la aplicación tiene permiso para grabar audio
    recorderController.checkPermission();
    // Cuando se completa la reproducción, establecer isPlaying en false
    playerController.onCompletion.listen((_) {
      playerController.seekTo(0);
      state = state.copyWith(isPlaying: false);
    });
  }

  Future<String> _getFilePath() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    _filePath = path.join(appDocumentsDir.path, 'voice_note.wav');
    return _filePath!;
  }

  Future<void> startRecording() async {
    final filePath = await _getFilePath();
    if (recorderController.hasPermission) {
      recorderController.reset();
      recorderController.record(path: filePath);
      state = state.copyWith(isRecording: true);
    }
  }

  Future<void> stopRecording() async {
    final filePath = await recorderController.stop(false);
    if (filePath != null) {
      final file = File(filePath);
      state = state.copyWith(isRecording: false, audioFile: file);
    }
  }

  Future<void> playLocalAudio() async {
    if (state.audioFile == null) return;
    playerController.stopPlayer();
    state = state.copyWith(audioFile: File(_filePath!));
    await playerController.preparePlayer(
      path: _filePath!,
    );
    playerController.startPlayer();
    state = state.copyWith(isPlaying: true);
  }

  Future<void> stopLocalAudio() async {
    await playerController.stopPlayer();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> pauseLocalAudio() async {
    await playerController.pausePlayer();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> uploadAudio(BuildContext context) async {
    try {
      if (state.audioFile == null) return;

      final fileName = 'voice_note_${DateTime.now()}.wav';

      Reference storageRef =
          FirebaseStorage.instance.ref().child('voice_notes').child(fileName);

      File file = File(_filePath.toString());
      uploadTask = storageRef.putFile(file);

      uploadTask!.snapshotEvents.listen((event) {
        final totalBytes = event.totalBytes;
        final bytesTransferred = event.bytesTransferred;
        final currentProgress = bytesTransferred / totalBytes;
        state = state.copyWith(uploadProgress: currentProgress);
      });

      final snapshot = await uploadTask!.whenComplete(() {
        // Mostrar alerta aquí
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('¡Subida completada!'),
              content: Text('El archivo se ha subido con éxito.'),
              actions: [
                TextButton(
                  onPressed: () => {
                    // Restablecer el progreso de carga
                    state = state.copyWith(uploadProgress: 0),
                    Navigator.of(context).pop()
                  },
                  child: Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      });

      final downloadUrl = await snapshot.ref.getDownloadURL();
      state = state.copyWith(downloadUrl: downloadUrl, uploadProgress: null);
    } on firebase_core.FirebaseException catch (e) {
      // Mostrar alerta de error específico
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error de subida'),
            content: Text('Código de error: ${e.code}\nMensaje: ${e.message}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Aceptar'),
              ),
            ],
          ),
        );
      }
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

  Future<List<String>> fetchAudioFiles() async {
    try {
      final ListResult result =
          await FirebaseStorage.instance.ref('voice_notes').listAll();

      // Obtén las URLs de descarga de cada archivo
      final List<String> downloadUrls = await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()).toList(),
      );

      final List<String> fileNames = result.items.map((ref) {
        return path.basename(ref.fullPath);
      }).toList();

      print('Nombres de archivo: $fileNames \nURLs de descarga: $downloadUrls');

      return [...fileNames, ...downloadUrls];
      
    } catch (e) {
      print('Error al obtener grabaciones: $e');
      return [];
    }
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
