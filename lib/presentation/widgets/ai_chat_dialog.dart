import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/gemma_viewmodel.dart';

class AiChatDialog extends StatefulWidget {
  const AiChatDialog({super.key});

  @override
  State<AiChatDialog> createState() => _AiChatDialogState();
}

class _AiChatDialogState extends State<AiChatDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final gemmaVM = Provider.of<GemmaViewModel>(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.smart_toy, color: Colors.deepPurple),
          const SizedBox(width: 8),
          const Text("Asistente IA"),
          const Spacer(),
          if (!gemmaVM.isModelReady)
            IconButton(
              icon: const Icon(Icons.add_chart),
              onPressed: () async {
                await gemmaVM.loadModel();
                setState(() {});
              },
              tooltip: "Cargar modelo .task",
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gemmaVM.lastResponse.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  gemmaVM.lastResponse,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Ej: Cliente Juan compró azúcar a 20 Bs",
                border: const OutlineInputBorder(),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  if (_controller.text.trim().isEmpty) return;
                  setState(() => _loading = true);
                  await gemmaVM.processCommand(_controller.text);
                  _controller.clear();
                  setState(() => _loading = false);
                },
          child: const Text("Enviar"),
        ),
      ],
    );
  }
}
