import 'package:flutter/material.dart';
import '../widgets/ai_chat_dialog.dart';

class HomePage extends StatelessWidget {
  final Widget child;
  const HomePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child, // la página actual (customers, products...)
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.chat),
        onPressed: () =>
            showDialog(context: context, builder: (_) => const AiChatDialog()),
      ),
    );
  }
}
