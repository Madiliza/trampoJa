import 'package:flutter/material.dart';
import 'package:trampoja_app/utils/app_colors.dart'; // Certifique-se de que o caminho está correto

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
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _localControllers;

  @override
  void initState() {
    super.initState();
    _localControllers = widget.controllers.map(
      (key, value) => MapEntry(key, TextEditingController(text: value.text)),
    );
  }

  @override
  void dispose() {
    _localControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  TextInputType _getKeyboardType(String key) {
    switch (key.toLowerCase()) {
      case 'phone':
      case 'telefone':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      case 'aboutme':
      case 'sobre mim':
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  int? _getMaxLines(String key) {
    return (key.toLowerCase() == 'aboutme' || key.toLowerCase() == 'sobre mim') ? 5 : 1;
  }

  IconData? _getIcon(String key) {
    switch (key.toLowerCase()) {
      case 'nome':
        return Icons.person;
      case 'email':
        return Icons.email;
      case 'telefone':
        return Icons.phone;
      case 'senha':
        return Icons.lock;
      case 'sobre mim':
      case 'aboutme':
        return Icons.info;
      default:
        return Icons.text_fields;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Formulário
            Form(
              key: _formKey,
              child: Column(
                children: _localControllers.entries.map((entry) {
                  final label = entry.key[0].toUpperCase() + entry.key.substring(1);
                  final isReadOnly = entry.key.toLowerCase() == 'email' || entry.key.toLowerCase() == 'senha';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: entry.value,
                      readOnly: isReadOnly,
                      keyboardType: _getKeyboardType(entry.key),
                      maxLines: _getMaxLines(entry.key),
                      style: const TextStyle(color: textColorPrimary),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          _getIcon(entry.key),
                          color: isReadOnly ? Colors.grey : primaryColor,
                        ),
                        labelText: label,
                        labelStyle: const TextStyle(color: textColorSecondary),
                        hintText: 'Digite sua ${label.toLowerCase()}',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: isReadOnly ? Colors.grey.shade100 : Colors.grey.shade50,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: errorColor, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: errorColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (!isReadOnly && (value == null || value.trim().isEmpty)) {
                          return 'Este campo não pode ser vazio.';
                        }
                        return null;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botão Cancelar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: textColorSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(width: 12),

                // Botão Salvar
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final data = _localControllers.map((key, value) => MapEntry(key, value.text.trim()));
                      widget.onSave(data);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: branco,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}