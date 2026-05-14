import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:file_picker/file_picker.dart';

class GemmaHelper {
  static InferenceModel? _model;
  static InferenceChat? _chat;
  static bool _isReady = false;
  static String? _lastModelName; // inutilizable

  static bool get isReady => _isReady;

  static Future<void> loadModelFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['task'],
    );
    if (result == null) throw Exception("No se seleccionó ningún archivo");

    final path = result.files.single.path!;
    final name = result.files.single.name;
    _lastModelName = name;

    // Instalar si no existe
    final installed = await FlutterGemma.isModelInstalled(name);
    if (!installed) {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromFile(path).install();
    }

    // Crear modelo (usar CPU para compatibilidad)
    final plugin = FlutterGemmaPlugin.instance;
    _model = await plugin.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: PreferredBackend.cpu,
      maxTokens: 2048,
    );
    _chat = await _model!.createChat();
    _isReady = true;
  }

  static Future<String> promptToJson(String userInput) async {
    if (!_isReady || _chat == null) {
      throw Exception(
        "Modelo no cargado. Selecciona un archivo .task primero.",
      );
    }

    String prompt =
        """
You are a JSON engine for an ERP system.
Given a natural language instruction, output ONLY a valid JSON object with the following structure:

{
  "tool": "sales|customer|product|inventory|purchase",
  "action": "create|update|delete|query",
  "data": { ... }
}

Examples:
Input: "Cliente Juan compró azúcar a 20 Bs"
Output: {"tool":"sales","action":"create","data":{"customer":"Juan","product":"azúcar","price":20,"currency":"Bs"}}

Input: "Registrar nuevo producto arroz a 2.5 Bs"
Output: {"tool":"product","action":"create","data":{"name":"arroz","price":2.5,"currency":"Bs"}}

Now process: $userInput
"""; // el error es userInput dice Const variables must be initialized with a constant value.
    // Try changing the initializer to be a constant expression.dartconst_initialized_with_non_constant_value

    await _chat!.clearHistory();
    await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));
    String full = "";
    await _chat!.generateChatResponseAsync().listen((resp) {
      if (resp is TextResponse) full += resp.token;
    }).asFuture();
    return _sanitize(full);
  }

  static String _sanitize(String raw) {
    var clean = raw.trim();
    if (clean.startsWith('```json')) clean = clean.substring(7);
    if (clean.startsWith('```')) clean = clean.substring(3);
    if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
    clean = clean.trim();
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start != -1 && end != -1) clean = clean.substring(start, end + 1);
    return clean;
  }
}
