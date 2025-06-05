// lib/screens/jobScreen/dialogs/create_job_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trampoja_app/services/job_service.dart';
import 'package:trampoja_app/utils/app_colors.dart'; // Importe suas cores

class CreateJobDialog extends StatefulWidget {
  final String userId;

  const CreateJobDialog({super.key, required this.userId});

  @override
  State<CreateJobDialog> createState() => _CreateJobDialogState();
}

class _CreateJobDialogState extends State<CreateJobDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final JobService _jobService = JobService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submitJob() async {
    if (_formKey.currentState!.validate()) {
      try {
        double? jobValue;
        if (_valueController.text.isNotEmpty) {
          jobValue = double.tryParse(
            _valueController.text.replaceAll(',', '.'),
          );
        }

        await _jobService.addJob(
          title: _titleController.text,
          description: _descriptionController.text,
          value: jobValue,
          createdByUserId: widget.userId,
        );
        if (!mounted) return;
        Navigator.of(context).pop(); // Fecha o diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga criada com sucesso!')),
        );
      } catch (e) {
        print('Erro ao criar vaga: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar vaga: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: branco,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text(
        'Criar Nova Vaga',
        style: TextStyle(color: cinzaEscuro, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título da Vaga',
                  labelStyle: const TextStyle(color: cinzaEscuro),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: laranjaVivo),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descrição da Vaga',
                  labelStyle: const TextStyle(color: cinzaEscuro),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: laranjaVivo),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                // Altera para permitir a vírgula e configurar o teclado numérico
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  // Permite dígitos e apenas uma vírgula para números decimais
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*,?\d{0,2}$')),
                ],
                decoration: InputDecoration(
                  labelText: 'Valor (Opcional)',
                  hintText: 'Ex: 150,00', // Ajuste o hintText para usar vírgula
                  labelStyle: const TextStyle(color: cinzaEscuro),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: laranjaVivo),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: cinzaEscuro)),
        ),
        ElevatedButton(
          onPressed: _submitJob,
          style: ElevatedButton.styleFrom(
            backgroundColor: laranjaVivo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Criar Vaga', style: TextStyle(color: branco)),
        ),
      ],
    );
  }
}
