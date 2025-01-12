import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAudio(String filePath) async {
    final fileName = filePath.split('/').last;
    final ref = _storage.ref().child('audio_notes/$fileName');
    final uploadTask = ref.putFile(File(filePath));

    final snapshot = await uploadTask.whenComplete(() => {});
    return await snapshot.ref.getDownloadURL();
  }
}
