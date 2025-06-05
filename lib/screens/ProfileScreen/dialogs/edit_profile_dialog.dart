import 'package:flutter/material.dart';

class EditProfileDialog extends StatefulWidget {
  final String title;
  final Map<String, TextEditingController> controllers;
  final Function(Map<String, dynamic>) onSave;

  const EditProfileDialog({
    super.key,
    required this.title,
    required this.controllers,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  // Uma cópia local dos controladores para que possamos descartá-los
  // caso o diálogo seja cancelado.
  late Map<String, TextEditingController> _localControllers;

  @override
  void initState() {
    super.initState();
    _localControllers = widget.controllers;
  }

  @override
  void dispose() {
    // Não descartar os controladores aqui se eles foram passados de fora,
    // apenas se foram criados aqui. No seu caso, eles vêm de fora, então não descarta.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          children: _localControllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: entry.key,
                ),
                readOnly: entry.key == 'Email' || entry.key == 'Senha', // Não permitir editar email/senha diretamente aqui
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final data = _localControllers.map((key, value) => MapEntry(key, value.text.trim()));
            widget.onSave(data);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}