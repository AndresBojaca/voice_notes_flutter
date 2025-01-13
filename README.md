# Aplicación de Notas de Voz

Esta aplicación permite a los usuarios grabar, reproducir, visualizar y subir notas de voz. Aprovecha las capacidades de Flutter junto con paquetes externos para ofrecer una experiencia interactiva de audio.

## Características
- **Grabación de Audio:** Graba audio de alta calidad usando el micrófono del dispositivo.
- **Reproducción de Audio:** Reproduce archivos de audio grabados.
- **Visualización de Forma de Onda:** Visualización en tiempo real durante la grabación y la reproducción.
- **Subir Audio:** Sube archivos de audio grabados a Firebase Storage.
- **Indicador de Progreso:** Muestra el progreso de subida con una barra de progreso circular animada.

---

## Dependencias

La aplicación utiliza los siguientes paquetes de Flutter:

- `flutter_riverpod`: Para la gestión del estado.
- `just_audio`: Para la reproducción de audio.
- `audio_waveforms`: Para visualizar formas de onda de audio.
- `firebase_storage`: Para subir archivos de audio a Firebase.
- `path_provider`: Para gestionar rutas de archivos.
- `record`: Para manejar la grabación de audio.
- `path`: Para la manipulación de rutas.

---

## Estructura de Carpetas

```
lib/
├── main.dart
├── audio_recorder/
│   ├── controller/
│   │   └── audio_controller.dart
│   ├── state/
│   │   └── audio_state.dart
│   └── views/
│       └── audio_screen.dart
└── widgets/
    └── audio_visualizer.dart
```

---

## Uso

### 1. Grabar Audio
- Toca el **botón del micrófono** para comenzar a grabar.
- Aparecerá una forma de onda mostrando la entrada de audio en tiempo real.

### 2. Reproducir Audio
- Toca el **botón de reproducción** para escuchar el audio grabado.
- La forma de onda del audio se mostrará durante la reproducción.
- Puedes alternar entre **reproducir** y **pausar**.

### 3. Subir Audio
- Toca el **botón de subida** para subir el archivo grabado a Firebase Storage.
- Un indicador de progreso circular mostrará el porcentaje de subida.

### 4. Reproducir Audio Descargado
- Después de subirlo, puedes reproducir el audio directamente desde la nube.

---

## Configuración de Firebase

1. Configura un proyecto en Firebase.
2. Agrega tu archivo `google-services.json` o `GoogleService-Info.plist` en las carpetas correspondientes de la plataforma.
3. Asegúrate de habilitar Firebase Storage en la consola de Firebase.
4. Actualiza tu proyecto de Flutter para incluir las dependencias de Firebase.

---

## Puntos Destacados del Código

### Grabación de Audio
```dart
Future<void> startRecording() async {
  final filePath = await _getFilePath();
  if (await _recorder.hasPermission()) {
    recorderController.reset();
    await _recorder.start(const RecordConfig(), path: filePath);
    state = state.copyWith(isRecording: true);
  }
}
```

### Reproducción de Audio
```dart
Future<void> playAudio() async {
  if (state.audioFile == null) return;
  if (playerController.playerState == PlayerState.playing) {
    await playerController.stop();
  }
  await playerController.preparePlayer(
    path: state.audioFile!.path,
    shouldExtractWaveform: true,
  );
  await playerController.seekTo(0);
  await playerController.startPlayer();
}
```

### Subida de Audio
```dart
Future<void> uploadAudio() async {
  if (state.audioFile == null) return;
  final fileName = 'voice_note_${DateTime.now()}.wav';
  final storageRef = FirebaseStorage.instance.ref().child('voice_notes/$fileName');
  uploadTask = storageRef.putFile(File(state.audioFile!.path));

  uploadTask!.snapshotEvents.listen((event) {
    final progress = event.bytesTransferred / event.totalBytes;
    state = state.copyWith(uploadProgress: progress);
  });

  final snapshot = await uploadTask!.whenComplete(() {});
  final downloadUrl = await snapshot.ref.getDownloadURL();
  state = state.copyWith(downloadUrl: downloadUrl);
}
```

---

## Capturas de Pantalla

### Pantalla de Grabación
- Botón de micrófono para iniciar/detener la grabación.
- Visualización de la forma de onda en tiempo real.

### Pantalla de Reproducción
- Botón de reproducción/pausa con visualización de la forma de onda.

### Progreso de Subida
- Indicador de progreso circular que muestra el porcentaje de subida.

---

## Posibles Mejoras
- **Recortar Audio:** Permitir a los usuarios recortar el audio grabado.
- **Soporte para Múltiples Archivos:** Manejar varios archivos de audio.
- **Gestión de Almacenamiento en la Nube:** Agregar soporte para eliminar o gestionar archivos subidos.
- **Modo Oscuro:** Proveer un tema en modo oscuro.

---

## Contribución
Siéntete libre de bifurcar este repositorio y enviar pull requests para nuevas características o correcciones de errores.

---

## Licencia
Este proyecto está licenciado bajo la Licencia MIT.

