import 'package:erp_mobile/utils/whisper_helper.dart';
import 'package:erp_mobile/domain/entities/customer.dart';
import 'package:erp_mobile/domain/entities/product.dart';
import 'package:erp_mobile/domain/entities/purchase.dart';
import 'package:erp_mobile/domain/entities/sale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _confirmingUnload = false;

  @override
  void initState() {
    super.initState();
    _initWhisper();
  }

  Future<void> _initWhisper() async {
    try {
      await WhisperHelper.initialize();
      setState(() {});
    } catch (e) {
      _showNotification("Error al inicializar voz: $e", isError: true);
    }
  }

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

  Future<void> _startRecording() async {
    try {
      await WhisperHelper.startRecording();
      setState(() => _isRecording = true);
      _showNotification("🎙️ Grabando... Presiona nuevamente para detener");
    } catch (e) {
      _showNotification("Error al iniciar grabación: $e", isError: true);
    }
  }

  Future<void> _stopRecordingAndTranscribe() async {
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    try {
      final transcribedText = await WhisperHelper.stopRecordingAndTranscribe();

      if (transcribedText != null && transcribedText.isNotEmpty) {
        setState(() {
          _controller.text = transcribedText;
        });
        _showNotification("✅ Audio transcrito correctamente");
      } else {
        _showNotification("No se pudo transcribir el audio", isError: true);
      }
    } catch (e) {
      _showNotification("Error en transcripción: $e", isError: true);
    } finally {
      setState(() => _isTranscribing = false);
    }
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
      _showNotification("Modelo descargado de memoria");
    }
  }

  void _clearChat(GemmaViewModel gemmaVM) {
    gemmaVM.clearResponse();
    _controller.clear();
    _showNotification("Conversación limpiada");
  }

  Future<void> _sendMessage(GemmaViewModel gemmaVM) async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _showNotification("Por favor escribe un mensaje", isError: true);
      return;
    }

    // ✅ Si el modelo no está cargado, mostrar mensaje y salir
    if (!gemmaVM.isModelReady) {
      _showNotification(
        "⚠️ Primero carga un modelo usando el botón 'Cargar Modelo'",
        isError: true,
      );
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
          _showNotification("✅ Cliente ${customer.name} creado exitosamente");
          if (widget.onCustomerCreated != null)
            widget.onCustomerCreated!(customer);
        },
        onProductCreated: (product) {
          _showNotification("✅ Producto ${product.name} creado exitosamente");
          if (widget.onProductCreated != null)
            widget.onProductCreated!(product);
        },
        onSaleCreated: (sale) {
          _showNotification("✅ Venta creada - Total: ${sale.total} Bs");
          if (widget.onSaleCreated != null) widget.onSaleCreated!(sale);
        },
        onPurchaseCreated: (purchase) {
          _showNotification(
            "✅ Compra creada - Proveedor: ${purchase.supplierName}",
          );
          if (widget.onPurchaseCreated != null)
            widget.onPurchaseCreated!(purchase);
        },
        onInventoryAdjusted: () {
          _showNotification("✅ Inventario ajustado correctamente");
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

  @override
  void dispose() {
    WhisperHelper.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gemmaVM = Provider.of<GemmaViewModel>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isModelReady = gemmaVM.isModelReady;

    // Actualizar estado local con el estado de WhisperHelper
    if (_isRecording != WhisperHelper.isRecording) {
      _isRecording = WhisperHelper.isRecording;
    }

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
                  if (isModelReady && gemmaVM.lastResponse.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, size: 20),
                      onPressed: _confirmingUnload
                          ? null
                          : () => _clearChat(gemmaVM),
                      tooltip: "Limpiar conversación",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (isModelReady)
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
                      color: isModelReady
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
                          color: isModelReady
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
                              color: isModelReady
                                  ? Colors.deepPurple.shade200
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Respuesta del asistente",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isModelReady
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
                                        "Escribe o habla para dar instrucciones",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (!isModelReady)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            "⚠️ Modelo no cargado. Usa 'Cargar Modelo' para comenzar",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.orange.shade400,
                                              fontSize: 12,
                                            ),
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
            // ✅ Campo de texto y botones - SIEMPRE habilitados
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
                          enabled:
                              !_loading, // ✅ Siempre habilitado, independiente del modelo
                          decoration: InputDecoration(
                            hintText:
                                "Ej: Crea un cliente llamado Juan con teléfono 78592060",
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
                      _buildMicrophoneButton(
                        gemmaVM,
                      ), // ✅ Siempre visible y funcional
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
                      // Botón de cargar modelo (si no está listo)
                      if (!isModelReady)
                        ElevatedButton.icon(
                          onPressed: gemmaVM.isProcessing
                              ? null
                              : () async {
                                  await gemmaVM.loadModel();
                                  setState(() {});
                                  _showNotification(
                                    "Modelo cargado correctamente",
                                  );
                                },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text("Cargar Modelo"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                          ),
                        ),
                      // Botón de enviar (si está listo)
                      if (isModelReady)
                        ElevatedButton.icon(
                          onPressed: (_loading || !isModelReady)
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

  Widget _buildMicrophoneButton(GemmaViewModel gemmaVM) {
    // ✅ Micrófono siempre funcional (no depende del modelo)
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isRecording)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.shade700.withValues(alpha: 2),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        if (_isTranscribing)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.shade700.withValues(alpha: 0.2),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: _isRecording
                ? Colors.red.shade700
                : (_isTranscribing
                      ? Colors.orange.shade700
                      : Colors.deepPurple),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
            ),
            onPressed: !_isTranscribing
                ? () async {
                    if (_isRecording) {
                      await _stopRecordingAndTranscribe();
                      setState(() {});
                    } else {
                      await _startRecording();
                      setState(() {});
                    }
                  }
                : null,
            tooltip: _isRecording ? "Detener y transcribir" : "Grabar voz",
          ),
        ),
      ],
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
}
