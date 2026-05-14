import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:file_picker/file_picker.dart';

class CreateCustomerTool {
  static const Tool spec = Tool(
    name: 'createCustomer',
    description: 'Creates a new customer in the ERP system.',
    parameters: {
      "type": "object",
      "properties": {
        "name": {"type": "string", "description": "Full name of the customer."},
        "email": {"type": "string", "description": "Email address."},
        "phone": {"type": "string", "description": "Phone number."},
        "address": {"type": "string", "description": "Physical address."},
        "document": {"type": "string", "description": "Tax ID or document."},
      },
      "required": ["name"],
    },
  );
}

class GemmaHelper {
  static InferenceModel? _model;
  static bool _isReady = false;

  static bool get isReady => _isReady;
  static InferenceModel? get model => _model;

  static Future<void> loadModelFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['task'],
    );
    if (result == null) throw Exception("No se seleccionó ningún archivo");

    final path = result.files.single.path!;
    final name = result.files.single.name;

    print("📁 Archivo seleccionado: $name");
    print("📁 Ruta: $path");

    // 1. PRIMERO: Instalar el modelo (esto lo hace disponible para getActiveModel)
    print("🔄 Instalando modelo...");
    await FlutterGemma.installModel(
      modelType: ModelType.qwen,
    ).fromFile(path).install();
    print("✅ Modelo instalado correctamente");

    // 2. SEGUNDO: Verificar que se instaló
    final isInstalled = await FlutterGemma.isModelInstalled(name);
    print("📦 ¿Modelo instalado en caché? $isInstalled");

    // 3. TERCERO: Obtener el modelo activo
    print("🔄 Obteniendo modelo activo...");
    _model = await FlutterGemma.getActiveModel(
      maxTokens: 2048,
      preferredBackend: PreferredBackend.cpu,
    );

    _isReady = true;
    print("✅ Modelo listo para usar");
  }

  static Future<InferenceChat> createChatWithTools() async {
    if (!_isReady || _model == null) {
      throw Exception(
        "Modelo no cargado. Asegúrate de haber seleccionado un archivo .task",
      );
    }
    return await _model!.createChat(
      tools: [CreateCustomerTool.spec],
      toolChoice: ToolChoice.auto,
      supportsFunctionCalls: true,
    );
  }
}
