import 'package:app_ia_llm/utils/gemma_helper.dart';
import 'package:flutter/material.dart';

class GemmaViewModel extends ChangeNotifier {
  bool _isModelReady = false;
  String _lastResponse = "";

  bool get isModelReady => _isModelReady;
  String get lastResponse => _lastResponse;

  Future<void> loadModel() async {
    try {
      await GemmaHelper.loadModelFromFile();
      _isModelReady = true;
      _lastResponse = "✅ Modelo cargado correctamente";
      notifyListeners();
    } catch (e) {
      _lastResponse = "❌ Error: $e";
      notifyListeners();
    }
  }

  Future<String> processCommand(String userInput) async {
    if (!_isModelReady) return "⚠️ Primero carga un modelo (icono + arriba)";
    try {
      final json = await GemmaHelper.promptToJson(userInput);
      _lastResponse = json;
      notifyListeners();
      return json;
    } catch (e) {
      _lastResponse = "Error: $e";
      notifyListeners();
      return _lastResponse;
    }
  }

  void clearResponse() {
    _lastResponse = "";
    notifyListeners();
  }
}
