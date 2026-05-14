// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_gemma/flutter_gemma.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:file_picker/file_picker.dart';
// import 'core/di/injection_container.dart' as di;

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await FlutterGemma.initialize();
//   await dotenv.load(fileName: ".env");
//   await di.init();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Gemma Local AI',
//       theme: ThemeData.dark(useMaterial3: true),
//       home: const GemmaPage(),
//     );
//   }
// }

// class GemmaPage extends StatefulWidget {
//   const GemmaPage({super.key});

//   @override
//   State<GemmaPage> createState() => _GemmaPageState();
// }

// class _GemmaPageState extends State<GemmaPage> {
//   final TextEditingController _promptController = TextEditingController();
//   String _response = "";
//   bool _isModelReady = false;
//   bool _isGenerating = false;
//   bool _isModelSelected = false;
//   bool _isInstalling = false;
//   bool _isCreatingModel = false;
//   InferenceModel? _model;
//   InferenceChat? _chat;
//   String _statusMessage = "";
//   String? _selectedModelPath;
//   String _selectedModelName = "";
//   double _selectedModelSizeMB = 0;
//   String _backendUsed = "";

//   @override
//   void initState() {
//     super.initState();
//     _checkPermissions();
//   }

//   Future<void> _checkPermissions() async {
//     if (await Permission.storage.shouldShowRequestRationale) {
//       await Permission.storage.request();
//     }
//   }

//   // ============================================================
//   // SELECCIONAR MODELO CON FILE PICKER
//   // ============================================================
//   Future<void> _selectModelFile() async {
//     try {
//       setState(() {
//         _statusMessage = "Abrir selector de archivos...";
//         _response = _statusMessage;
//       });

//       final result = await FilePicker.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['task'],
//         allowMultiple: false,
//       );

//       if (result != null && result.files.single.path != null) {
//         _selectedModelPath = result.files.single.path!;
//         _selectedModelName = result.files.single.name;
//         final fileSizeBytes = await File(_selectedModelPath!).length();
//         _selectedModelSizeMB = fileSizeBytes / (1024 * 1024);

//         setState(() {
//           _isModelSelected = true;
//           _isInstalling = true;
//           _statusMessage =
//               "Instalando modelo (esto puede tomar varios minutos)...";
//           _response =
//               "📁 $_selectedModelName\n📏 ${_selectedModelSizeMB.toStringAsFixed(2)} MB\n\n🔄 $_statusMessage";
//         });

//         await _loadModelFromFile();
//       } else {
//         setState(() {
//           _statusMessage = "No se seleccionó ningún archivo.";
//           _response = _statusMessage;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _response = "❌ Error al seleccionar archivo:\n$e";
//         _isInstalling = false;
//       });
//     }
//   }

//   // ============================================================
//   // CARGAR MODELO (INSTALACIÓN)
//   // ============================================================
//   Future<void> _loadModelFromFile() async {
//     if (_selectedModelPath == null) return;

//     try {
//       // 1. Verificar archivo
//       setState(() {
//         _statusMessage = "Paso 1/3: Verificando archivo...";
//         _response =
//             "📁 $_selectedModelName\n📏 ${_selectedModelSizeMB.toStringAsFixed(2)} MB\n\n🔄 $_statusMessage";
//       });
//       await Future.delayed(
//         const Duration(milliseconds: 500),
//       ); // para que se vea el cambio

//       final modelFile = File(_selectedModelPath!);
//       if (!await modelFile.exists())
//         throw Exception("El archivo ya no existe.");

//       // 2. Instalar modelo (solo si no está instalado)
//       final modelName = _selectedModelPath!.split('/').last;
//       final isInstalled = await FlutterGemma.isModelInstalled(modelName);

//       if (!isInstalled) {
//         setState(() {
//           _statusMessage =
//               "Paso 2/3: Instalando modelo (puede tardar 1-2 minutos)...";
//           _response =
//               "📁 $_selectedModelName\n📏 ${_selectedModelSizeMB.toStringAsFixed(2)} MB\n\n🔄 $_statusMessage";
//         });
//         await FlutterGemma.installModel(
//           modelType: ModelType.gemmaIt,
//         ).fromFile(_selectedModelPath!).install();
//       } else {
//         setState(() {
//           _statusMessage = "Paso 2/3: Modelo ya estaba en caché.";
//           _response =
//               "📁 $_selectedModelName\n📏 ${_selectedModelSizeMB.toStringAsFixed(2)} MB\n\n🔄 $_statusMessage";
//         });
//         await Future.delayed(const Duration(seconds: 1));
//       }

//       // 3. Pasar a creación del modelo
//       setState(() {
//         _isInstalling = false;
//         _isCreatingModel = true;
//         _statusMessage =
//             "Paso 3/3: Creando instancia del modelo (último paso, ~40 seg)...";
//         _response =
//             "📁 $_selectedModelName\n📏 ${_selectedModelSizeMB.toStringAsFixed(2)} MB\n\n✅ Modelo instalado\n\n🔄 $_statusMessage";
//       });

//       await _createModelDirectly();
//     } catch (e) {
//       setState(() {
//         _response = "❌ Error instalando modelo:\n$e";
//         _isModelSelected = false;
//         _isInstalling = false;
//         _isCreatingModel = false;
//       });
//     }
//   }

//   // ============================================================
//   // CREAR MODELO (CPU por defecto)
//   // ============================================================
//   Future<void> _createModelDirectly() async {
//     final plugin = FlutterGemmaPlugin.instance;

//     // Intentar CPU primero (más compatible)
//     try {
//       setState(() {
//         _statusMessage =
//             "Inicializando en CPU (esto puede tardar hasta 40 segundos)...";
//         _response =
//             "📁 $_selectedModelName\n📏 ${_selectedModelSizeMB.toStringAsFixed(2)} MB\n\n✅ Modelo instalado\n\n🔄 $_statusMessage";
//       });

//       _model = await plugin.createModel(
//         modelType: ModelType.gemmaIt,
//         preferredBackend: PreferredBackend.cpu,
//         maxTokens: 2048,
//       );
//       _backendUsed = "CPU";
//       await _finishChatCreation();
//     } catch (e) {
//       // Fallback a GPU si CPU falla
//       setState(() {
//         _statusMessage = "CPU falló, intentando con GPU...";
//         _response = "⚠️ Error en CPU: $e\n\n🔄 $_statusMessage";
//       });
//       try {
//         _model = await plugin.createModel(
//           modelType: ModelType.gemmaIt,
//           preferredBackend: PreferredBackend.gpu,
//           maxTokens: 2048,
//         );
//         _backendUsed = "GPU";
//         await _finishChatCreation();
//       } catch (e2) {
//         setState(() {
//           _response = "❌ No se pudo crear el modelo:\nCPU: $e\nGPU: $e2";
//           _isModelSelected = false;
//           _isCreatingModel = false;
//         });
//       }
//     }
//   }

//   Future<void> _finishChatCreation() async {
//     _chat = await _model!.createChat(
//       systemInstruction:
//           "Eres un asistente que convierte texto a JSON. "
//           "Respondes SOLAMENTE con JSON válido. "
//           "NUNCA agregues texto adicional o explicaciones.",
//     );

//     if (mounted) {
//       setState(() {
//         _isModelReady = true;
//         _isCreatingModel = false;
//         _response =
//             "✅ ¡MODELO LISTO! 🎉\n\n"
//             "📁 $_selectedModelName\n"
//             "📏 ${_selectedModelSizeMB.toStringAsFixed(2)} MB\n"
//             "⚙️ Backend: $_backendUsed\n\n"
//             "📝 Escribe una descripción y obtendrás JSON.\n"
//             "Ejemplo: 'Cliente compró azúcar a 20 Bs'";
//         _statusMessage = "";
//       });
//     }
//   }

//   // ============================================================
//   // GENERAR JSON (igual que antes)
//   // ============================================================
//   Future<void> _generateJSON() async {
//     if (!_isModelReady || _isGenerating || _chat == null) return;

//     setState(() {
//       _isGenerating = true;
//       _response = "🤔 Generando respuesta...";
//     });

//     try {
//       final userInput = _promptController.text.trim();
//       if (userInput.isEmpty) {
//         setState(() {
//           _response = "⚠️ Por favor, ingresa una descripción.";
//           _isGenerating = false;
//         });
//         return;
//       }

//       final prompt =
//           """
// You are a JSON engine.

// CRITICAL RULES:
// - Output ONLY valid JSON
// - No markdown
// - No explanations
// - No extra text
// - No comments
// - Use double quotes only

// JSON SCHEMA:
// {
//   "tool": string,
//   "action": string,
//   "entity": string,
//   "payload": {
//     "product": string,
//     "price": number,
//     "currency": string,
//     "customer": string
//   }
// }

// VALID TOOLS: sales, customer, inventory, accounting, loans
// VALID ACTIONS: create, update, delete, query

// EXAMPLES:

// INPUT: "Cliente compró azúcar a 20 Bs"
// OUTPUT: {"tool":"sales","action":"create","entity":"sale","payload":{"product":"azúcar","price":20,"currency":"Bs","customer":"cliente"}}

// INPUT: "$userInput"
// OUTPUT:""";

//       await _chat!.clearHistory();
//       await _chat!.addQueryChunk(Message.text(text: prompt, isUser: true));

//       String fullResponse = "";
//       await _chat!.generateChatResponseAsync().listen((response) {
//         if (response is TextResponse) {
//           fullResponse += response.token;
//           if (mounted) {
//             setState(() {
//               _response = _sanitizeJSON(fullResponse);
//             });
//           }
//         }
//       }).asFuture();

//       _chat = await _model!.createChat(
//         systemInstruction:
//             "Eres un asistente que convierte texto a JSON. Respondes SOLAMENTE con JSON válido.",
//       );
//     } catch (e) {
//       setState(() => _response = "❌ Error: $e");
//     } finally {
//       setState(() => _isGenerating = false);
//     }
//   }

//   String _sanitizeJSON(String raw) {
//     String clean = raw.trim();
//     if (clean.startsWith('```json'))
//       clean = clean.substring(7);
//     else if (clean.startsWith('```'))
//       clean = clean.substring(3);
//     if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
//     clean = clean.trim();
//     final start = clean.indexOf('{');
//     final end = clean.lastIndexOf('}');
//     if (start != -1 && end != -1 && end > start)
//       clean = clean.substring(start, end + 1);
//     return clean;
//   }

//   Future<void> _resetModel() async {
//     _chat?.close();
//     _model?.close();
//     setState(() {
//       _isModelReady = false;
//       _isModelSelected = false;
//       _isInstalling = false;
//       _isCreatingModel = false;
//       _selectedModelPath = null;
//       _selectedModelName = "";
//       _selectedModelSizeMB = 0;
//       _backendUsed = "";
//       _response = "";
//       _statusMessage = "";
//     });
//     await _selectModelFile();
//   }

//   @override
//   void dispose() {
//     _chat?.close();
//     _model?.close();
//     _promptController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gemma 3 - Conversor a JSON'),
//         backgroundColor: Colors.deepPurple,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add_chart),
//             onPressed: _isGenerating ? null : _resetModel,
//             tooltip: "Cargar otro modelo",
//           ),
//           if (_isModelReady)
//             Padding(
//               padding: const EdgeInsets.only(right: 12),
//               child: Chip(
//                 label: Text(_backendUsed),
//                 backgroundColor: Colors.green.shade800,
//                 labelStyle: const TextStyle(fontSize: 11),
//               ),
//             ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Tarjeta de información del modelo (si está seleccionado)
//             if (_isModelSelected && _selectedModelName.isNotEmpty)
//               Card(
//                 color: Colors.deepPurple.shade900,
//                 margin: const EdgeInsets.only(bottom: 16),
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           const Icon(Icons.model_training, size: 20),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               _selectedModelName,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         "Tamaño: ${_selectedModelSizeMB.toStringAsFixed(2)} MB",
//                       ),
//                       if (_isInstalling || _isCreatingModel)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 12),
//                           child: Column(
//                             children: [
//                               LinearProgressIndicator(
//                                 backgroundColor: Colors.grey.shade800,
//                                 valueColor: const AlwaysStoppedAnimation(
//                                   Colors.deepPurple,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 _statusMessage,
//                                 style: const TextStyle(fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),

//             // Si el modelo NO está listo, mostrar mensaje de bienvenida
//             if (!_isModelReady && !_isModelSelected)
//               Expanded(
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(
//                         Icons.model_training,
//                         size: 64,
//                         color: Colors.grey,
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         "No hay modelo cargado",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       const Text(
//                         "Toca el ícono + en la barra superior\npara seleccionar un archivo .task",
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//             // Campos de entrada y botón solo si modelo listo
//             if (_isModelReady) ...[
//               TextField(
//                 controller: _promptController,
//                 maxLines: 4,
//                 decoration: InputDecoration(
//                   border: const OutlineInputBorder(),
//                   labelText: "Describe la acción",
//                   hintText: "Ej: Cliente compró azúcar a 20 Bs",
//                   enabled: !_isGenerating,
//                   filled: true,
//                   fillColor: Colors.grey.shade900,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: _isGenerating ? null : _generateJSON,
//                   icon: _isGenerating
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Icon(Icons.code),
//                   label: Text(_isGenerating ? "Generando..." : "Generar JSON"),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     backgroundColor: Colors.deepPurple,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],

//             // Área de resultados JSON
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade700),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: const BoxDecoration(
//                         color: Colors.grey,
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         "JSON Generado",
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     Expanded(
//                       child: SingleChildScrollView(
//                         padding: const EdgeInsets.all(12),
//                         child: SelectableText(
//                           _response.isEmpty
//                               ? (_isModelReady
//                                     ? "💡 Escribe algo y presiona 'Generar JSON'"
//                                     : "💡 Selecciona un modelo para comenzar")
//                               : _response,
//                           style: const TextStyle(
//                             fontFamily: 'monospace',
//                             fontSize: 13,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_router.dart';
import 'presentation/viewmodels/gemma_viewmodel.dart';
import 'presentation/viewmodels/customers_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  await dotenv.load(fileName: ".env");
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => di.sl<CustomersViewModel>()..load(),
        ),
        ChangeNotifierProvider(create: (_) => di.sl<GemmaViewModel>()),
      ],
      child: MaterialApp.router(
        title: "ERP IA",
        routerConfig: appRouter,
        theme: ThemeData.dark(useMaterial3: true),
      ),
    );
  }
}
