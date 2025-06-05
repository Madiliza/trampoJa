import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:trampoja_app/models/JobModel.dart'; // Certifique-se que JobModel está importado e correto
import 'package:trampoja_app/utils/app_colors.dart';

class AcceptedJobsList extends StatelessWidget {
  final List<String> jobIds;

  const AcceptedJobsList({super.key, required this.jobIds});

  @override
  Widget build(BuildContext context) {
    if (jobIds.isEmpty) {
      return Center( // Centraliza a mensagem
        child: Text(
          'Nenhum trabalho concluído ainda. Vamos lá!',
          style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: textColorSecondary.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: jobIds.map((jobId) => _buildJobAcceptedItem(jobId)).toList(),
    );
  }

  Widget _buildJobAcceptedItem(String jobId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(color: primaryColor), // Indicador de carregamento
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Erro ao carregar trabalho: ${snapshot.error}', style: const TextStyle(color: errorColor)),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Trabalho não encontrado ou removido.', style: TextStyle(fontStyle: FontStyle.italic, color: textColorSecondary)),
          );
        }

        final jobData = snapshot.data!.data() as Map<String, dynamic>;
        final jobTitle = jobData['title'] ?? 'Título indisponível';
        final jobValue = (jobData['value'] as num?)?.toStringAsFixed(2).replaceAll('.', ',');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0), // Mais espaçamento
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColorPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (jobValue != null)
                Text(
                  'R\$ $jobValue',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: primaryColor, // Valor em destaque
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}