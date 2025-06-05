import 'package:flutter/material.dart';
import 'package:trampoja_app/services/job_service.dart';
import 'package:trampoja_app/utils/app_colors.dart';

class CreateJobDialog extends StatefulWidget {
  final String userId;

  const CreateJobDialog({super.key, required this.userId});

  @override
  State<CreateJobDialog> createState() => _CreateJobDialogState();
}

class _CreateJobDialogState extends State<CreateJobDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final JobService _jobService = JobService();

  void _submitJob() async {
    if (_titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
      final double? jobValue = double.tryParse(_valueController.text.replaceAll(',', '.'));

      try {
        await _jobService.addJob(
          title: _titleController.text,
          description: _descriptionController.text,
          value: jobValue,
          createdByUserId: widget.userId,
        );
        if (!mounted) return;
        _titleController.clear();
        _descriptionController.clear();
        _valueController.clear();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga criada com sucesso!')),
        );
      } catch (e) {
        print('Erro ao adicionar vaga: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar vaga: $e')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o título e a descrição da vaga.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: const Text(
        'Criar Nova Vaga',
        style: TextStyle(color: cinzaEscuro, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título da Vaga',
                labelStyle: const TextStyle(color: cinzaEscuro),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: laranjaSuave),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: laranjaVivo, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: cinzaClaro.withOpacity(0.5),
              ),
              cursorColor: laranjaVivo,
              style: const TextStyle(color: cinzaEscuro),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descrição da Vaga',
                labelStyle: const TextStyle(color: cinzaEscuro),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: laranjaSuave),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: laranjaVivo, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: cinzaClaro.withOpacity(0.5),
              ),
              cursorColor: laranjaVivo,
              style: const TextStyle(color: cinzaEscuro),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor (R\$)',
                labelStyle: const TextStyle(color: cinzaEscuro),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: laranjaSuave),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: laranjaVivo, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: cinzaClaro.withOpacity(0.5),
              ),
              cursorColor: laranjaVivo,
              style: const TextStyle(color: cinzaEscuro),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _titleController.clear();
            _descriptionController.clear();
            _valueController.clear();
          },
          child: const Text('Cancelar', style: TextStyle(color: cinzaEscuro)),
        ),
        ElevatedButton(
          onPressed: _submitJob,
          style: ElevatedButton.styleFrom(
            backgroundColor: laranjaVivo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text(
            'Criar Vaga',
            style: TextStyle(color: branco, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}