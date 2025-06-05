// lib/screens/jobScreen/dialogs/applied_jobs_dialog.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trampoja_app/models/ApplicationModel.dart';
import 'package:trampoja_app/models/JobModel.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/utils/app_colors.dart';
import 'package:trampoja_app/screens/ProfileScreen/ViewProfileScreen.dart'; // Para ver o perfil do contratante

class AppliedJobsDialog extends StatelessWidget {
  final String currentUserId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppliedJobsDialog({super.key, required this.currentUserId});

  String _getApplicationStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'accepted':
        return 'Aceita';
      case 'declined':
        return 'Recusada';
      default:
        return 'Desconhecido';
    }
  }

  Color _getApplicationStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
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
        'Minhas Candidaturas',
        style: TextStyle(color: cinzaEscuro, fontWeight: FontWeight.bold),
      ),
      content: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collectionGroup('applications') // Busca em todas as subcoleções 'applications'
            .where('applicantId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar candidaturas: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Você ainda não se candidatou a nenhuma vaga.'));
          }

          final applications = snapshot.data!.docs.map((doc) => Application.fromFirestore(doc)).toList();

          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                final String jobId = application.jobId;

                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('jobs').doc(jobId).get(),
                  builder: (context, jobSnapshot) {
                    if (jobSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text('Carregando...'));
                    }
                    if (jobSnapshot.hasError || !jobSnapshot.hasData || !jobSnapshot.data!.exists) {
                      return const ListTile(title: Text('Erro ao carregar dados da vaga.'));
                    }

                    final job = Job.fromFirestore(jobSnapshot.data!);
                    final String? contratanteId = job.createdByUserId;

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(contratanteId).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(title: Text('Carregando contratante...'));
                        }
                        if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return const ListTile(title: Text('Erro ao carregar perfil do contratante.'));
                        }

                        final contratanteData = UserModel.fromDocument(userSnapshot.data!);
                        final String contratanteName = contratanteData.name;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: contratanteData.photoUrl.isNotEmpty
                                        ? NetworkImage(contratanteData.photoUrl)
                                        : const NetworkImage('https://via.placeholder.com/150'),
                                  ),
                                  title: Text(
                                    job.title,
                                    style: const TextStyle(color: cinzaEscuro, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Contratante: $contratanteName', style: const TextStyle(color: cinzaEscuro)),
                                      Text(
                                        'Status: ${_getApplicationStatusText(application.status)}',
                                        style: TextStyle(
                                          color: _getApplicationStatusColor(application.status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Ao tocar, pode levar para a tela de visualização do perfil do contratante
                                    Navigator.of(context).pop(); // Fecha o diálogo atual
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ViewProfileScreen(userId: contratanteId ?? ''),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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