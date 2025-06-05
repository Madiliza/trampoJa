import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trampoja_app/models/JobModel.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/screens/JobScreen/widgetsJob/job_card.dart';
import 'package:trampoja_app/screens/jobScreen/dialogs/create_job_dialog.dart';
import 'package:trampoja_app/utils/app_colors.dart'; // Importe as cores
import 'package:trampoja_app/services/job_service.dart'; // Importe o serviço

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final JobService _jobService = JobService(); // Instância do serviço

  /// Exclui uma vaga do Firestore e suas candidaturas associadas.
  /// Este método é passado como callback para JobCard.
  void _handleDeleteJob(String jobId) async {
    try {
      await _jobService.deleteJob(jobId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaga e candidaturas excluídas com sucesso!')),
      );
    } catch (e) {
      print('Erro ao excluir vaga: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir vaga: $e')),
      );
    }
  }

  // O _showApplicantsListDialog foi movido para dentro do JobCard,
  // então não precisamos dele aqui na JobScreen.
  // Criamos apenas um placeholder para o onShowApplicants do JobCard.
  void _handleShowApplicants(String jobId) {
    // A lógica de exibição do diálogo está dentro do JobCard agora.
    // Este callback pode ser vazio ou usado para algo mais se necessário.
  }

  /// Exibe um diálogo para o usuário criar uma nova vaga.
  void _showCreateJobDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateJobDialog(userId: userId); // Usa o novo widget de diálogo
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cinzaClaro,
      appBar: AppBar(
        title: const Text(
          'Vagas',
          style: TextStyle(color: branco, fontWeight: FontWeight.bold),
        ),
        backgroundColor: laranjaVivo,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = authSnapshot.data;

          if (currentUser == null) {
            return const Center(
              child: Text(
                'Faça login para ver as vagas.',
                style: TextStyle(fontSize: 18, color: cinzaEscuro),
              ),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userDocSnapshot.hasError || !userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
                return const Center(child: Text('Erro ao carregar dados do usuário.'));
              }

              final userData = UserModel.fromDocument(userDocSnapshot.data!);
              final isContratante = userData.userType == 'contratante';
              final isPrestador = userData.userType == 'prestador';

              Stream<QuerySnapshot> jobStream;
              if (isContratante) {
                jobStream = _firestore.collection('jobs')
                    .where('createdByUserId', isEqualTo: currentUser.uid)
                    .snapshots();
              } else {
                jobStream = _firestore.collection('jobs')
                    .where('accepted', isEqualTo: false)
                    .where('createdByUserId', isNotEqualTo: currentUser.uid)
                    .snapshots();
              }

              return StreamBuilder<QuerySnapshot>(
                stream: jobStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar vagas: ${snapshot.error}',
                        style: const TextStyle(color: cinzaEscuro),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: laranjaVivo));
                  }

                  final jobs = snapshot.data!.docs.map((doc) {
                    return Job.fromFirestore(doc);
                  }).toList();

                  if (jobs.isEmpty) {
                    return Center(
                      child: Text(
                        isContratante
                            ? 'Você ainda não criou nenhuma vaga.'
                            : 'Nenhuma vaga disponível no momento.',
                        style: const TextStyle(fontSize: 18, color: cinzaEscuro),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return JobCard(
                        job: job,
                        currentUserData: userData,
                        currentUser: currentUser,
                        onDeleteJob: _handleDeleteJob, // Passa o callback
                        onShowApplicants: _handleShowApplicants, // Passa o callback
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return Container();
          }
          final currentUser = authSnapshot.data;
          if (currentUser == null) {
            return Container();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(currentUser.uid).get(),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return Container();
              }
              if (userDocSnapshot.hasError || !userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
                return Container();
              }

              final userData = UserModel.fromDocument(userDocSnapshot.data!);
              final isContratante = userData.userType == 'contratante';

              if (isContratante) {
                return FloatingActionButton(
                  onPressed: () => _showCreateJobDialog(currentUser.uid),
                  backgroundColor: laranjaVivo,
                  child: const Icon(Icons.add, color: branco),
                );
              } else {
                return Container();
              }
            },
          );
        },
      ),
    );
  }
}