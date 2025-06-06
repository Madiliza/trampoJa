// lib/screens/jobScreen/dialogs/applicant_list_dialog.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trampoja_app/models/ApplicationModel.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/services/job_service.dart';
import 'package:trampoja_app/utils/app_colors.dart';
import 'package:trampoja_app/screens/ProfileScreen/ViewProfileScreen.dart';

class ApplicantListDialog extends StatelessWidget {
  final String jobId;
  final JobService _jobService = JobService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ApplicantListDialog({super.key, required this.jobId});

  /// Função para aceitar candidatura (agora usa o JobService)
  void _acceptApplication(BuildContext context, String applicationId, String applicantId) async {
    try {
      await _jobService.acceptApplication(jobId, applicationId, applicantId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidatura aceita e vaga atribuída!')),
      );
      Navigator.of(context).pop(); // Fecha o diálogo após aceitar
    } catch (e) {
      print('Erro ao aceitar candidatura: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar candidatura: $e')),
      );
    }
  }

  /// Função para recusar candidatura (agora usa o JobService)
  void _declineApplication(BuildContext context, String applicationId, String applicantId) async {
    try {
      await _jobService.declineApplication(jobId, applicationId, applicantId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidatura recusada.')),
      );
      // Não fecha o diálogo para permitir aceitar outro
    } catch (e) {
      print('Erro ao recusar candidatura: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao recusar candidatura: $e')),
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
        'Candidatos para esta Vaga',
        style: TextStyle(color: cinzaEscuro, fontWeight: FontWeight.bold),
      ),
      content: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('jobs').doc(jobId).collection('applications').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar candidaturas: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum candidato ainda.'));
          }

          final applications = snapshot.data!.docs.map((doc) => Application.fromFirestore(doc)).toList();

          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                final String applicantId = application.applicantId;

                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(applicantId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text('Carregando...'));
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const ListTile(title: Text('Erro ao carregar perfil do candidato.'));
                    }

                    final applicantData = UserModel.fromDocument(userSnapshot.data!);
                    final String applicantName = applicantData.name;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[200], // Adicionado para um fundo em caso de placeholder
                                backgroundImage: applicantData.photoUrl.isNotEmpty
                                    ? NetworkImage(applicantData.photoUrl) as ImageProvider
                                    : null, 
                                child: applicantData.photoUrl.isEmpty
                                    ? Icon(Icons.person, size: 40, color: Colors.grey[600]) // Ícone de pessoa como fallback
                                    : null,
                              ),
                              title: Text(
                                applicantName,
                                style: const TextStyle(color: cinzaEscuro, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                applicantData.profession.isNotEmpty ? applicantData.profession : 'Profissão não informada',
                                style: const TextStyle(color: cinzaEscuro),
                              ),
                              onTap: () {
                                Navigator.of(context).pop(); // Fecha o diálogo atual
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewProfileScreen(userId: applicantId), // <-- Correto
                                  ),
                                );
                              },
                            ),
                            if (application.status == 'pending')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _acceptApplication(context, application.id!, applicantId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Aceitar', style: TextStyle(color: branco)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _declineApplication(context, application.id!, applicantId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Recusar', style: TextStyle(color: branco)),
                                  ),
                                ],
                              )
                            else if (application.status == 'accepted')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                    const SizedBox(width: 5),
                                    const Text('Candidatura Aceita!', style: TextStyle(color: Color.fromARGB(255, 33, 114, 36), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            else if (application.status == 'declined')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
                                    const SizedBox(width: 5),
                                    const Text('Candidatura Recusada', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar', style: TextStyle(color: cinzaEscuro)),
        ),
      ],
    );
  }
}