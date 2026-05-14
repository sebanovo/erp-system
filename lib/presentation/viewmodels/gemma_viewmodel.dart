import 'package:app_ia_llm/utils/gemma_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/create_customer.dart';

class GemmaViewModel extends ChangeNotifier {
  final CreateCustomer _createCustomer = GetIt.instance<CreateCustomer>();

  bool _isModelReady = false;
  String _lastResponse = "";
  bool _isProcessing = false;
  InferenceChat? _chat;

  bool get isModelReady => _isModelReady;
  String get lastResponse => _lastResponse;
  bool get isProcessing => _isProcessing;

  Future<void> loadModel() async {
    try {
      await GemmaHelper.loadModelFromFile();
      // ✅ Crear chat CON las herramientas
      _chat = await GemmaHelper.createChatWithTools();
      _isModelReady = true;
      _lastResponse = "✅ Modelo cargado correctamente";
      notifyListeners();
    } catch (e) {
      _lastResponse = "❌ Error: $e";
      notifyListeners();
    }
  }

  Future<void> processCommand(
    String userInput, {
    Function(Customer)? onCustomerCreated,
  }) async {
    if (!_isModelReady || _chat == null) {
      _lastResponse = "⚠️ Primero carga un modelo";
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _lastResponse = "";
    notifyListeners();

    try {
      await _chat!.clearHistory();
      await _chat!.addQueryChunk(Message.text(text: userInput, isUser: true));

      // ✅ Escuchar respuesta - puede ser FunctionCallResponse o TextResponse
      await _chat!.generateChatResponseAsync().listen((response) async {
        if (response is FunctionCallResponse) {
          print("📞 Function call: ${response.name}");
          print("📦 Arguments: ${response.args}");

          if (response.name == 'createCustomer') {
            final args = response.args;
            final customer = Customer(
              id: '',
              name: args['name'] ?? '',
              email: args['email'],
              phone: args['phone'],
              address: args['address'],
              document: args['document'],
              isActive: true,
            );
            await _createCustomer.call(customer);
            _lastResponse = "✅ Cliente creado: ${customer.name}";
            if (onCustomerCreated != null) onCustomerCreated(customer);
            notifyListeners();
          } else {
            _lastResponse = "⚠️ Función desconocida: ${response.name}";
            notifyListeners();
          }
        } else if (response is TextResponse) {
          _lastResponse = response.token;
          notifyListeners();
        }
      }).asFuture();
    } catch (e) {
      _lastResponse = "Error: $e";
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> unloadModel() async {
    _chat?.close();
    _chat = null;
    _isModelReady = false;
    _lastResponse = "";
    _isProcessing = false;
    notifyListeners();

    print("✅ Modelo descargado de memoria");
  }

  void clearResponse() {
    _lastResponse = "";
    notifyListeners();
  }
}
