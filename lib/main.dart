import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma Local AI',
      theme: ThemeData.dark(useMaterial3: true),
      home: const GemmaPage(),
    );
  }
}

class GemmaPage extends StatefulWidget {
  const GemmaPage({super.key});

  @override
  State<GemmaPage> createState() => _GemmaPageState();
}

class _GemmaPageState extends State<GemmaPage> {
  final TextEditingController _promptController = TextEditingController();
  String _response = "";
  bool _isModelReady = false;
  bool _isGenerating = false;
  InferenceModel? _model;
  InferenceChat? _chat;
  String _statusMessage = "";

  static const String _modelFileName =
      "Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task";

  @override
  void initState() {
    super.initState();
    _loadModelFromAssets();
  }

  // ============================================================
  // FORZAR INSTALACIÓN DEL MODELO (siempre reinstala)
  // ============================================================
  Future<void> _loadModelFromAssets() async {
    setState(() {
      _statusMessage = "Instalando/Verificando modelo...";
      _response = _statusMessage;
    });

    try {
      // 🔥 OPCIÓN 1: Forzar reinstalación (borra y reinstala)
      // Es más lento pero garantiza que funcione
      setState(() {
        _statusMessage =
            "Reinstalando modelo (esto garantiza funcionamiento)...";
        _response = _statusMessage;
      });

      // Forzar reinstalación - elimina el anterior si existe y lo reinstala
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromAsset('assets/models/$_modelFileName').install();

      print("✅ Modelo instalado/reinstalado correctamente");
      setState(() {
        _statusMessage = "Modelo instalado correctamente.";
      });

      // Esperar un momento para que el sistema registre el modelo
      await Future.delayed(const Duration(milliseconds: 500));

      // 🔥 OPCIÓN 2: Usar createModel en lugar de getActiveModel
      await _createModelDirectly();
    } catch (e) {
      print("❌ Error: $e");
      setState(() {
        _response =
            "❌ Error cargando modelo:\n$e\n\n"
            "Verifica que:\n"
            "1. El archivo está en: assets/models/$_modelFileName\n"
            "2. pubspec.yaml tiene: assets:\n  - assets/models/\n"
            "3. El archivo .task no está corrupto\n"
            "4. Hiciste 'flutter clean' y 'flutter pub get'";
        _isModelReady = false;
        _statusMessage = "";
      });
    }
  }

  // ============================================================
  // CREAR MODELO DIRECTAMENTE (sin getActiveModel)
  // ============================================================
  Future<void> _createModelDirectly() async {
    setState(() {
      _statusMessage = "Creando instancia del modelo...";
    });

    // Usar el plugin directamente para crear el modelo
    final plugin = FlutterGemmaPlugin.instance;
    try {
      _model = await plugin.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.gpu,
        maxTokens: 2048,
      );

      print("✅ Modelo creado exitosamente");

      _chat = await _model!.createChat(
        systemInstruction:
            "Eres un asistente que convierte texto a JSON. "
            "Respondes SOLAMENTE con JSON válido. "
            "NUNCA agregues texto adicional o explicaciones.",
      );

      print("✅ Chat creado");

      if (mounted) {
        setState(() {
          _isModelReady = true;
          _response =
              "✅ Modelo Gemma 3 listo!\n\n"
              "📝 Escribe una descripción y obtendrás JSON.\n"
              "Ejemplo: 'Cliente compró azúcar a 20 Bs'\n\n"
              "🎯 Salida esperada:\n"
              '{"tool":"sales","action":"create","entity":"sale","payload":{"product":"azúcar","price":20,"currency":"Bs","customer":"cliente"}}';
          _statusMessage = "";
        });
      }
    } catch (e) {
      print("❌ Error al crear modelo: $e");
      setState(() {
        _response =
            "❌ Error al crear el modelo: $e\n\n"
            "Intentando con CPU...";
        _statusMessage = "";
      });

      // Reintentar con CPU
      try {
        _model = await plugin.createModel(
          modelType: ModelType.gemmaIt,
          preferredBackend: PreferredBackend.cpu,
          maxTokens: 2048,
        );

        _chat = await _model!.createChat(
          systemInstruction:
              "Eres un asistente que convierte texto a JSON. "
              "Respondes SOLAMENTE con JSON válido.",
        );

        if (mounted) {
          setState(() {
            _isModelReady = true;
            _response =
                "✅ Modelo Gemma 3 listo (usando CPU)!\n\n"
                "📝 Escribe una descripción y obtendrás JSON.";
            _statusMessage = "";
          });
        }
      } catch (e2) {
        setState(() {
          _response =
              "❌ Error definitivo: $e2\n\n"
              "Posibles soluciones:\n"
              "1. El modelo .task podría ser incompatible\n"
              "2. Prueba descargando el modelo desde la red\n"
              "3. Verifica que el archivo no esté corrupto";
          _isModelReady = false;
        });
      }
    }
  }

  // ============================================================
  // GENERAR JSON (con prompt mejorado)
  // ============================================================
  Future<void> _generateJSON() async {
    if (!_isModelReady || _isGenerating || _chat == null) return;

    setState(() {
      _isGenerating = true;
      _response = "";
    });

    try {
      final userInput = _promptController.text.trim();

      if (userInput.isEmpty) {
        setState(() {
          _response = "⚠️ Por favor, ingresa una descripción.";
          _isGenerating = false;
        });
        return;
      }

      final prompt =
          """
You are a JSON engine.

CRITICAL RULES:
- Output ONLY valid JSON
- No markdown
- No explanations
- No extra text
- No comments
- Use double quotes only

JSON SCHEMA:
{
  "tool": string,
  "action": string,
  "entity": string,
  "payload": {
    "product": string,
    "price": number,
    "currency": string,
    "customer": string
  }
}

VALID TOOLS: sales, customer, inventory, accounting, loans
VALID ACTIONS: create, update, delete, query

EXAMPLES:

INPUT: "Cliente compró azúcar a 20 Bs"
OUTPUT: {"tool":"sales","action":"create","entity":"sale","payload":{"product":"azúcar","price":20,"currency":"Bs","customer":"cliente"}}

INPUT: "$userInput"
OUTPUT:""";

      await _chat!.clearHistory();
      await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));

      String fullResponse = "";
      await _chat!.generateChatResponseAsync().listen((response) {
        if (response is TextResponse) {
          fullResponse += response.token;
          if (mounted) {
            String cleanResponse = _sanitizeJSON(fullResponse);
            setState(() {
              _response = cleanResponse;
            });
          }
        }
      }).asFuture();

      // Recriar chat para próxima consulta
      _chat = await _model!.createChat(
        systemInstruction:
            "Eres un asistente que convierte texto a JSON. Respondes SOLAMENTE con JSON válido.",
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _response = "❌ Error: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  // ============================================================
  // LIMPIAR JSON
  // ============================================================
  String _sanitizeJSON(String raw) {
    String clean = raw.trim();

    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    clean = clean.trim();

    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      clean = clean.substring(start, end + 1);
    }

    return clean;
  }

  @override
  void dispose() {
    _chat?.close();
    _model?.close();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemma 3 - Conversor a JSON'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_statusMessage)),
                  ],
                ),
              ),

            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Describe la acción",
                hintText: "Ej: Cliente compró azúcar a 20 Bs",
                enabled: _isModelReady && !_isGenerating,
                filled: true,
                fillColor: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isModelReady && !_isGenerating)
                    ? _generateJSON
                    : null,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.code),
                label: Text(_isGenerating ? "Generando..." : "Generar JSON"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "JSON Generado",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _response.isEmpty
                              ? "💡 El JSON aparecerá aquí..."
                              : _response,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
