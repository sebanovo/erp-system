import 'package:app_ia_llm/domain/entities/customer.dart';
import 'package:app_ia_llm/domain/entities/product.dart';
import 'package:app_ia_llm/domain/entities/purchase.dart';
import 'package:app_ia_llm/domain/entities/sale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../viewmodels/gemma_viewmodel.dart';

class AiChatDialog extends StatefulWidget {
  const AiChatDialog({
    super.key,
    this.onCustomerCreated,
    this.onProductCreated,
    this.onSaleCreated,
    this.onPurchaseCreated,
  });
  final Function(Customer)? onCustomerCreated;
  final Function(Product)? onProductCreated;
  final Function(Sale)? onSaleCreated;
  final Function(Purchase)? onPurchaseCreated; // ← Agregar

  @override
  State<AiChatDialog> createState() => _AiChatDialogState();
}

class _AiChatDialogState extends State<AiChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  bool _isListening = false;
  bool _confirmingUnload = false;
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        print("Speech status: $status");
        if (status == 'notAvailable') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El reconocimiento de voz no está disponible"),
            ),
          );
        }
      },
      onError: (error) {
        print("Speech error: $error");
        setState(() => _isListening = false);
      },
    );
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);

      // Mostrar indicador visual
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "🎤 Escuchando... Presiona el micrófono nuevamente para detener",
          ),
          duration: Duration(seconds: 2),
        ),
      );

      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
        listenFor: const Duration(days: 365), // ← Sin límite práctico
        pauseFor: const Duration(seconds: 30), // ← Pausa larga de 30 segundos
        partialResults: true,
        localeId: "es_ES",
        onSoundLevelChange: (level) {
          // Opcional: puedes usar esto para animaciones
          // print("Nivel de sonido: $level");
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo inicializar el reconocimiento de voz"),
        ),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🔴 Grabación detenida"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _unloadModel(GemmaViewModel gemmaVM) async {
    setState(() => _confirmingUnload = true);

    final shouldUnload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Quitar modelo?"),
        content: const Text(
          "El modelo se descargará de la memoria.\n"
          "Tendrás que volver a cargarlo para usarlo nuevamente.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Quitar"),
          ),
        ],
      ),
    );

    setState(() => _confirmingUnload = false);

    if (shouldUnload == true) {
      await gemmaVM.unloadModel();
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Modelo descargado. Usa 'Cargar Modelo' para volver a cargarlo",
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _clearChat(GemmaViewModel gemmaVM) {
    gemmaVM.clearResponse();
    _controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Conversación limpiada"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gemmaVM = Provider.of<GemmaViewModel>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - Fijo en la parte superior
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusIndicator(gemmaVM),
                  const Spacer(),
                  // Botón para limpiar conversación
                  if (gemmaVM.isModelReady && gemmaVM.lastResponse.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, size: 20),
                      onPressed: _confirmingUnload
                          ? null
                          : () => _clearChat(gemmaVM),
                      tooltip: "Limpiar conversación",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  // Botón para quitar modelo
                  if (gemmaVM.isModelReady)
                    IconButton(
                      icon: _confirmingUnload
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever, size: 20),
                      onPressed: _confirmingUnload
                          ? null
                          : () => _unloadModel(gemmaVM),
                      tooltip: "Quitar modelo",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            // Área de respuesta con scroll
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gemmaVM.isModelReady
                          ? Colors.deepPurple.shade300
                          : Colors.grey.shade700,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: gemmaVM.isModelReady
                              ? Colors.deepPurple.shade800
                              : Colors.grey.shade800,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 14,
                              color: gemmaVM.isModelReady
                                  ? Colors.deepPurple.shade200
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Respuesta del asistente",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: gemmaVM.isModelReady
                                    ? Colors.deepPurple.shade200
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Contenido con scroll
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          child: gemmaVM.lastResponse.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 20),
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 48,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        gemmaVM.isModelReady
                                            ? "Escribe o habla para dar instrucciones"
                                            : "Primero carga un modelo",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                )
                              : SelectableText(
                                  gemmaVM.lastResponse,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Campo de texto y botones - Parte inferior fija
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo de texto con micrófono
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLines: 3,
                          minLines: 1,
                          enabled: !_loading && gemmaVM.isModelReady,
                          decoration: InputDecoration(
                            hintText: gemmaVM.isModelReady
                                ? "Ej: Crea un cliente llamado Juan con teléfono 78592060"
                                : "Primero carga un modelo",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: _loading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _sendMessage(gemmaVM),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón de micrófono (ahora con indicador visual)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isListening)
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.shade700.withOpacity(0.2),
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? Colors.red.shade700
                                  : (gemmaVM.isModelReady
                                        ? Colors.deepPurple
                                        : Colors.grey),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                              ),
                              onPressed: gemmaVM.isModelReady
                                  ? (_isListening
                                        ? _stopListening
                                        : _startListening)
                                  : null,
                              tooltip: _isListening
                                  ? "Detener grabación"
                                  : "Usar voz",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cerrar"),
                      ),
                      const SizedBox(width: 8),
                      if (!gemmaVM.isModelReady)
                        ElevatedButton.icon(
                          onPressed: gemmaVM.isProcessing
                              ? null
                              : () async {
                                  await gemmaVM.loadModel();
                                  setState(() {});
                                },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text("Cargar Modelo"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                          ),
                        ),
                      if (gemmaVM.isModelReady)
                        ElevatedButton.icon(
                          onPressed: (_loading || !gemmaVM.isModelReady)
                              ? null
                              : () => _sendMessage(gemmaVM),
                          icon: const Icon(Icons.send, size: 18),
                          label: Text(
                            gemmaVM.isProcessing ? "Procesando..." : "Enviar",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(GemmaViewModel gemmaVM) {
    if (gemmaVM.isProcessing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade900,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 6),
            Text("Procesando...", style: TextStyle(fontSize: 11)),
          ],
        ),
      );
    }

    if (!gemmaVM.isModelReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text("Sin modelo", style: TextStyle(fontSize: 11)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text("Modelo listo", style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _sendMessage(GemmaViewModel gemmaVM) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _loading = true;
      _controller.clear();
    });

    await gemmaVM.processCommand(
      text,
      onCustomerCreated: widget.onCustomerCreated, // DUDOSO
      onProductCreated: widget.onProductCreated,
      onSaleCreated: widget.onSaleCreated,
      onPurchaseCreated: widget.onPurchaseCreated, // ← Agregar
    );

    setState(() => _loading = false);
    _scrollToBottom();
  }
}
