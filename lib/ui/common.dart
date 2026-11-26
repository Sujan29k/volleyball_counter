import 'package:flutter/material.dart';
import '../state/app_controller.dart';

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(padding: const EdgeInsets.all(20), children: children),
      ),
    ),
  );
}

class SaveError extends StatelessWidget {
  final AppController controller;
  const SaveError(this.controller, {super.key});
  @override
  Widget build(BuildContext context) => controller.error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            controller.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
}
