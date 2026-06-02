import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

class WhisperHelper {
  static WhisperController? _controller;
  static bool _isInitialized = false;
  static String? _currentRecordingPath;
  static final AudioRecorder _recorder = AudioRecorder();
  static bool _isRecording = false;

  static WhisperController get controller {
    _controller ??= WhisperController();
    return _controller!;
  }

  static bool get isInitialized => _isInitialized;
  static bool get isRecording => _isRecording;

  // Modelo: tiny para debug, base para release
  static WhisperModel get _model =>
      kReleaseMode ? WhisperModel.base : WhisperModel.tiny;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint(" [WHISPER] Inicializando...");

    // Solicitar permiso de micrófono
    if (!await _recorder.hasPermission()) {
      throw Exception("Permiso de micrófono denegado");
    }

    // Descargar modelo si no existe
    await controller.downloadModel(_model);
    _isInitialized = true;
    debugPrint("[WHISPER] Modelo listo: ${_model.name}");
  }

  static Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw Exception("No hay permiso de micrófono");
    }

    if (_isRecording) {
      debugPrint("[WHISPER] Ya hay una grabación en curso");
      return;
    }

    final appDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentRecordingPath = '${appDir.path}/recording_$timestamp.wav';

    await _recorder.start(
      const RecordConfig(
        sampleRate: 16000,
        encoder: AudioEncoder.wav,
        numChannels: 1,
      ),
      path: _currentRecordingPath!,
    );

    _isRecording = true;
    debugPrint("[WHISPER] Grabando: ${_currentRecordingPath!.split('/').last}");
  }

  static Future<String?> stopRecordingAndTranscribe() async {
    if (!_isRecording) {
      debugPrint("[WHISPER] No hay grabación activa");
      return null;
    }

    final startTime = DateTime.now();

    debugPrint("[WHISPER] Deteniendo grabación...");

    // Detener grabación
    final audioPath = await _recorder.stop();
    _isRecording = false;

    if (audioPath == null) {
      debugPrint("[WHISPER] No se pudo detener la grabación");
      return null;
    }

    debugPrint("[WHISPER] Archivo guardado: ${audioPath.split('/').last}");
    debugPrint("[WHISPER] Iniciando transcripción con modelo: ${_model.name}");

    // Transcribir con Whisper
    final result = await controller.transcribe(
      model: _model,
      audioPath: audioPath,
      lang: 'es',
      withTimestamps: true,
      threads: 4,
    );

    final totalTime = DateTime.now().difference(startTime).inMilliseconds;

    if (result != null && result.transcription.text.isNotEmpty) {
      // Logs detallados como en el ejemplo
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("[TRANSCRIPTION COMPLETE]");
      debugPrint("Total time (inc. conversion): ${totalTime}ms");
      debugPrint("Text: ${result.transcription.text}");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      return result.transcription.text;
    } else {
      debugPrint("[WHISPER] Transcripción fallida o vacía");
      return null;
    }
  }

  static Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.cancel();
      _isRecording = false;
      _currentRecordingPath = null;
      debugPrint("[WHISPER] Grabación cancelada");
    }
  }

  static Future<void> dispose() async {
    await _recorder.dispose();
    _controller = null;
    _isInitialized = false;
    _isRecording = false;
    debugPrint("[WHISPER] Recursos liberados");
  }
}
