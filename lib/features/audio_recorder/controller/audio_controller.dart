import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'audio_state.dart';


final recordingStateProvider = StateNotifierProvider<AudioController, RecordingState>((ref) {
  return AudioController();
});

class AudioController extends StateNotifier<RecordingState> {
   
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final RecorderController recorderController = RecorderController();

  String? _filePath;

  AudioController() : super(RecordingState());

  Future<String> _getFilePath() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    // _filePath = path.join(appDocumentsDir.absolute, 'voice_note.wav');
    _filePath = '${appDocumentsDir.absolute}/voice_note.wav';
    return _filePath!;
  }
  Future<void> startRecording() async {
    final filePath = await _getFilePath();
    if (await _recorder.hasPermission()) {
      recorderController.reset();
      await _recorder.start(
        const RecordConfig(),
        path: filePath);
      state = state.copyWith(isRecording: true);
    }
  }

  Future<void> stopRecording() async {
    recorderController.stop();
    final filePath = await _recorder.stop();
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
  }

  Future<void> uploadAudio() async {
    if (state.audioFile == null) return;

    final fileName = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.wav';
    final storageRef = FirebaseStorage.instance.ref().child('voice_notes/$fileName');
    print('File path: $_filePath');

    File file = File(_filePath!);
    final fileSize = file.lengthSync();
    print('Tamaño del archivo: $fileSize bytes');

    try {
      await storageRef.putFile(file);
    } on firebase_core.FirebaseException catch (e) {
      print('Error al subir archivo: ${e.code} - ${e.message}');
    } catch (e) {
      print('Error inesperado: $e');
    }


    // uploadTask.snapshotEvents.listen((event) {
    //   final progress = event.bytesTransferred / event.totalBytes;
    //   state = state.copyWith(uploadProgress: progress);
    // });

    // final snapshot = await uploadTask!.whenComplete(() {});
    // final downloadUrl = await snapshot.ref.getDownloadURL();
    // state = state.copyWith(downloadUrl: downloadUrl, uploadProgress: null);
  }

  Future<void> playAudio() async {
    if (state.downloadUrl == null) return;
    await _player.setUrl(state.downloadUrl!);
    _player.play();
  }

  Future<void> stopAudio() async {
    await _player.stop();
  }
}

final audioControllerProvider =
    StateNotifierProvider<AudioController, RecordingState>((ref) {
  return AudioController();
});
