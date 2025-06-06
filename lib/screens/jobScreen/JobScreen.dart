// lib/screens/jobScreen/JobScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trampoja_app/models/JobModel.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/screens/jobScreen/dialogs/applied_jobs_dialog.dart';
import 'package:trampoja_app/screens/jobScreen/dialogs/create_job_dialog.dart';
import 'package:trampoja_app/screens/jobScreen/widgetsJob/job_card.dart';
import 'package:trampoja_app/services/job_service.dart';
import 'package:trampoja_app/utils/app_colors.dart';

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final JobService _jobService = JobService();

  /// Exclui uma vaga do Firestore e suas candidaturas associadas.
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

  /// Exibe um diálogo para o usuário criar uma nova vaga.
  void _showCreateJobDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateJobDialog(userId: userId);
      },
    );
  }

  /// Exibe o diálogo com as vagas para as quais o prestador aplicou.
  void _showAppliedJobsDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppliedJobsDialog(currentUserId: userId);
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
        actions: [
          StreamBuilder<User?>(
            stream: _auth.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink(); // Widget vazio enquanto carrega
              }
              final currentUser = authSnapshot.data;
              if (currentUser == null) {
                return const SizedBox.shrink();
              }
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(currentUser.uid).get(),
                builder: (context, userDocSnapshot) {
                  if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (userDocSnapshot.hasError || !userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final userData = UserModel.fromDocument(userDocSnapshot.data!);
                  final isPrestador = userData.userType == 'prestador';

                  if (isPrestador) {
                    return IconButton(
                      icon: const Icon(Icons.description, color: branco), // Ícone para "Minhas Candidaturas"
                      onPressed: () => _showAppliedJobsDialog(currentUser.uid),
                      tooltip: 'Minhas Candidaturas',
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
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

              Stream<QuerySnapshot> jobStream;
              if (isContratante) {
                jobStream = _firestore.collection('jobs')
                    .where('createdByUserId', isEqualTo: currentUser.uid)
                    .snapshots();
              } else {
                jobStream = _firestore.collection('jobs')
                    .where('accepted', isEqualTo: false) // Vagas não aceitas
                    .where('createdByUserId', isNotEqualTo: currentUser.uid) // Que não foram criadas por ele
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
                        onDeleteJob: _handleDeleteJob,
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
                  // === CORREÇÃO AQUI: Definir heroTag: null para este FAB ===
                  // Este FAB é condicional e não deve ter uma animação Hero que conflita
                  // com o FAB principal do Homepage.
                  heroTag: null,
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