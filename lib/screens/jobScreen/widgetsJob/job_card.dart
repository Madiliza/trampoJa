// lib/screens/jobScreen/widgets/job_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trampoja_app/models/JobModel.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/models/ApplicationModel.dart';
import 'package:trampoja_app/screens/jobScreen/dialogs/applicant_list_dialog.dart'; // Caminho corrigido para o diálogo de candidatos
import 'package:trampoja_app/utils/app_colors.dart';
import 'package:trampoja_app/services/job_service.dart';

class JobCard extends StatefulWidget {
  final Job job;
  final UserModel currentUserData;
  final User currentUser;
  final Function(String jobId) onDeleteJob; // Callback para excluir vaga

  const JobCard({
    super.key,
    required this.job,
    required this.currentUserData,
    required this.currentUser,
    required this.onDeleteJob,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  final JobService _jobService = JobService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Função para aplicar para vaga (agora usa o JobService)
  void _applyForJob() async {
    try {
      await _jobService.applyForJob(widget.job.id!, widget.currentUser.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidatura enviada com sucesso! Aguardando aprovação do contratante.')),
      );
    } catch (e) {
      print('Erro ao aplicar para vaga: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aplicar para vaga: $e')),
      );
    }
  }

  /// Novo método para exibir o diálogo de candidatos
  void _showApplicantsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ApplicantListDialog(jobId: widget.job.id!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isContratante = widget.currentUserData.userType == 'contratante';
    final isPrestador = widget.currentUserData.userType == 'prestador';

    return Card(
      color: const Color.fromARGB(255, 235, 235, 235),
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.job.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cinzaEscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.job.description,
              style: TextStyle(
                fontSize: 16,
                color: cinzaEscuro.withOpacity(0.8),
              ),
            ),
            if (widget.job.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Valor: R\$ ${widget.job.value!.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: laranjaVivo,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Lógica para Contratante
                if (isContratante) ...[
                  if (widget.job.accepted && widget.job.acceptedByUserId != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(widget.job.acceptedByUserId!).get(),
                      builder: (context, acceptedSnapshot) {
                        if (acceptedSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (acceptedSnapshot.hasError || !acceptedSnapshot.hasData || !acceptedSnapshot.data!.exists) {
                          return const Text('Prestador aceito não encontrado');
                        }
                        final acceptedName = UserModel.fromDocument(acceptedSnapshot.data!).name;
                        return Flexible(
                          child: Container(
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
                                Flexible(
                                  child: Text(
                                    'Atribuída: $acceptedName',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 33, 114, 36),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else // Se a vaga não foi aceita, verificar se há candidaturas
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('jobs').doc(widget.job.id!).collection('applications')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, applicationsSnapshot) {
                        if (applicationsSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (applicationsSnapshot.hasError) {
                          return Text('Erro: ${applicationsSnapshot.error}');
                        }

                        final pendingApplications = applicationsSnapshot.data!.docs.length;

                        if (pendingApplications > 0) {
                          return Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showApplicantsDialog, // Chama o novo método que exibe o diálogo
                              icon: const Icon(Icons.group, color: branco),
                              label: Text('Ver Candidatos ($pendingApplications)', style: const TextStyle(color: branco)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          );
                        } else {
                          // Se não há candidaturas pendentes e não foi aceita, mostra o botão de excluir
                          return Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onDeleteJob(widget.job.id!),
                              icon: const Icon(Icons.delete, color: branco),
                              label: const Text('Excluir', style: TextStyle(color: branco)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                ],
                // Lógica para Prestador
                if (isPrestador) ...[
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore.collection('jobs').doc(widget.job.id!).collection('applications')
                        .where('applicantId', isEqualTo: widget.currentUser.uid)
                        .get(),
                    builder: (context, myApplicationSnapshot) {
                      if (myApplicationSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      final myApplications = myApplicationSnapshot.data!.docs;
                      final hasApplied = myApplications.isNotEmpty;
                      final myApplication = hasApplied ? Application.fromFirestore(myApplications.first) : null;

                      if (hasApplied) {
                        if (myApplication!.status == 'accepted') {
                          return Container(
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
                                const Text(
                                  'Sua Candidatura Aceita!',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 33, 114, 36),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (myApplication.status == 'pending') {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, color: Colors.yellow.shade700, size: 20),
                                const SizedBox(width: 5),
                                const Text(
                                  'Sua Candidatura Pendente',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (myApplication.status == 'declined') {
                          return Container(
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
                                const Text(
                                  'Sua Candidatura Recusada!',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                      // Se não aplicou e a vaga não está aceita por ninguém, pode aplicar
                      if (!widget.job.accepted) {
                        return Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _applyForJob,
                            icon: const Icon(Icons.send, color: branco),
                            label: const Text('Candidatar-se', style: TextStyle(color: branco)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: laranjaVivo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        );
                      }
                      // Se a vaga já foi aceita por outro, não mostra botão
                      return Container();
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}