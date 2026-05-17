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
    this.onInventoryAdjusted,
  });
  final Function(Customer)? onCustomerCreated;
  final Function(Product)? onProductCreated;
  final Function(Sale)? onSaleCreated;
  final Function(Purchase)? onPurchaseCreated;
  final VoidCallback? onInventoryAdjusted;

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

  // ✅ Método para mostrar notificaciones
  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'notAvailable') {
          _showNotification(
            "El reconocimiento de voz no está disponible",
            isError: true,
          );
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        _showNotification("Error en el micrófono", isError: true);
      },
    );
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _showNotification("🎤 Escuchando... Habla ahora", isError: false);

      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
        listenFor: const Duration(days: 365),
        pauseFor: const Duration(seconds: 30),
        partialResults: true,
        localeId: "es_ES",
        onSoundLevelChange: (level) {},
      );
    } else {
      _showNotification(
        "No se pudo inicializar el reconocimiento de voz",
        isError: true,
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _showNotification("🔴 Grabación detenida", isError: false);
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
      _showNotification("Modelo descargado de memoria", isError: false);
    }
  }

  void _clearChat(GemmaViewModel gemmaVM) {
    gemmaVM.clearResponse();
    _controller.clear();
    _showNotification("Conversación limpiada", isError: false);
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
            // Header
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
            // Área de respuesta
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
            // Campo de texto y botones
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                                  _showNotification(
                                    "Modelo cargado correctamente",
                                    isError: false,
                                  );
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
    if (text.isEmpty) {
      _showNotification("Por favor escribe un mensaje", isError: true);
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _loading = true;
      _controller.clear();
    });

    try {
      await gemmaVM.processCommand(
        text,
        onCustomerCreated: (customer) {
          _showNotification(
            "✅ Cliente ${customer.name} creado exitosamente",
            isError: false,
          );
          if (widget.onCustomerCreated != null) {
            widget.onCustomerCreated!(customer);
          }
        },
        onProductCreated: (product) {
          _showNotification(
            "✅ Producto ${product.name} creado exitosamente",
            isError: false,
          );
          if (widget.onProductCreated != null) {
            widget.onProductCreated!(product);
          }
        },
        onSaleCreated: (sale) {
          _showNotification(
            "✅ Venta creada - Total: ${sale.total} Bs",
            isError: false,
          );
          if (widget.onSaleCreated != null) widget.onSaleCreated!(sale);
        },
        onPurchaseCreated: (purchase) {
          _showNotification(
            "✅ Compra creada - Proveedor: ${purchase.supplierName}",
            isError: false,
          );
          if (widget.onPurchaseCreated != null) {
            widget.onPurchaseCreated!(purchase);
          }
        },
        onInventoryAdjusted: () {
          _showNotification(
            "✅ Inventario ajustado correctamente",
            isError: false,
          );
          if (widget.onInventoryAdjusted != null) widget.onInventoryAdjusted!();
        },
      );
    } catch (e) {
      _showNotification(
        "❌ Error: ${e.toString().substring(0, 100)}",
        isError: true,
      );
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }
}
