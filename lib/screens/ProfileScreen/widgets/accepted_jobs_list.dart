import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trampoja_app/models/JobModel.dart';

class AcceptedJobsList extends StatelessWidget {
  final List<String> jobIds;

  const AcceptedJobsList({super.key, required this.jobIds});

  @override
  Widget build(BuildContext context) {
    if (jobIds.isEmpty) {
      return const Text(
        'Nenhum trabalho aceito ainda.',
        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
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
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Erro ao carregar trabalho: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Trabalho não encontrado.');
        }

        final jobData = snapshot.data!.data() as Map<String, dynamic>;
        final jobTitle = jobData['title'] ?? 'Título indisponível';
        final jobValue = (jobData['value'] as num?)?.toStringAsFixed(2).replaceAll('.', ',');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (jobValue != null) Text('R\$ $jobValue'),
            ],
          ),
        );
      },
    );
  }
}