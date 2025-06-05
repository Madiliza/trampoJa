import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trampoja_app/models/JobModel.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/models/ApplicationModel.dart';
import 'package:trampoja_app/utils/app_colors.dart';
import 'package:trampoja_app/services/job_service.dart';
import 'package:trampoja_app/screens/ProfileScreen/ViewProfileScreen.dart'; // Mantido para o _showApplicantsListDialog

class JobCard extends StatefulWidget {
  final Job job;
  final UserModel currentUserData;
  final User currentUser;
  final Function(String jobId) onDeleteJob; // Callback para excluir vaga
  final Function(String jobId) onShowApplicants; // Callback para mostrar candidatos

  const JobCard({
    super.key,
    required this.job,
    required this.currentUserData,
    required this.currentUser,
    required this.onDeleteJob,
    required this.onShowApplicants,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  final JobService _jobService = JobService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Necessário para StreamBuilders dentro do card

  // Função para aplicar para vaga (agora usa o JobService)
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

  // Exibe um diálogo com a lista de candidatos que aplicaram para a vaga.
  // Movemos o método _showApplicantsListDialog para cá, pois ele é específico do card
  void _showApplicantsListDialog(String jobId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                                    backgroundImage: applicantData.photoUrl.isNotEmpty
                                        ? NetworkImage(applicantData.photoUrl)
                                        : const NetworkImage('https://via.placeholder.com/150'),
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
                                        builder: (context) => ViewProfileScreen(userId: applicantId),
                                      ),
                                    );
                                  },
                                ),
                                if (application.status == 'pending')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          _jobService.acceptApplication(jobId, application.id!, applicantId).then((_) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Candidatura aceita e vaga atribuída!')),
                                              );
                                            }
                                            Navigator.of(context).pop(); // Fecha o diálogo
                                          }).catchError((e) {
                                            print('Erro ao aceitar candidatura: $e');
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erro ao aceitar candidatura: $e')),
                                              );
                                            }
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Aceitar', style: TextStyle(color: branco)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _jobService.declineApplication(jobId, application.id!, applicantId).then((_) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Candidatura recusada.')),
                                              );
                                            }
                                            // Não fecha o diálogo para permitir aceitar outro
                                          }).catchError((e) {
                                            print('Erro ao recusar candidatura: $e');
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erro ao recusar candidatura: $e')),
                                              );
                                            }
                                          });
                                        },
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
                              onPressed: () => _showApplicantsListDialog(widget.job.id!),
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
                          return Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onDeleteJob(widget.job.id!), // Usa o callback
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