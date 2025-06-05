import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trampoja_app/models/JobModel.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/models/ApplicationModel.dart'; // Importe o novo modelo de candidatura
import 'package:trampoja_app/screens/ProfileScreen/ViewProfileScreen.dart';

// Definição das cores da paleta
const Color laranjaVivo = Color(0xFFFF6F00);
const Color laranjaSuave = Color(0xFFFFA040);
const Color pessegoClaro = Color(0xFFFEE0B2);
const Color cinzaEscuro = Color(0xFF333333);
const Color cinzaClaro = Color(0xFFF5F5F5);
const Color branco = Color(0xFFFFFFFF);

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  /// Adiciona uma nova vaga à coleção 'jobs' no Firestore.
  /// A vaga será associada ao UID do usuário contratante que a criou.
  void _addJob(String userId) async {
    if (_titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
      final double? jobValue = double.tryParse(_valueController.text.replaceAll(',', '.'));

      final newJob = Job(
        id: _firestore.collection('jobs').doc().id, // Gera um ID antes de adicionar
        title: _titleController.text,
        description: _descriptionController.text,
        value: jobValue,
        createdByUserId: userId,
        // Removidos appliedByUserId, isPending e accepted/declined, pois agora são por aplicação
        accepted: false,
        declined: false,
        acceptedByUserId: null,
      );

      try {
        await _firestore.collection('jobs').doc(newJob.id).set(newJob.toFirestore());
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

  /// Exclui uma vaga do Firestore e suas candidaturas associadas.
  void _deleteJob(String jobId) async {
    try {
      // Deletar todas as candidaturas associadas à vaga
      final applications = await _firestore.collection('jobs').doc(jobId).collection('applications').get();
      for (var doc in applications.docs) {
        final app = Application.fromFirestore(doc);
        // Se a aplicação foi aceita, remover o jobId do jobsCompleted do prestador
        if (app.status == 'accepted') {
          await _firestore.collection('users').doc(app.applicantId).update({
            'jobsCompleted': FieldValue.arrayRemove([jobId]),
          });
        }
        await doc.reference.delete(); // Deleta o documento da aplicação
      }

      // Finalmente, exclui a vaga em si
      await _firestore.collection('jobs').doc(jobId).delete();
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
              onPressed: () => _addJob(userId),
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
      },
    );
  }

  /// Função para o prestador aplicar para uma vaga.
  void _applyForJob(String jobId, String prestadorId) async {
    try {
      final newApplication = Application(
        jobId: jobId,
        applicantId: prestadorId,
        status: 'pending',
        appliedAt: Timestamp.now(),
      );

      await _firestore.collection('jobs').doc(jobId).collection('applications').add(newApplication.toFirestore());

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

  /// Exibe um diálogo com a lista de candidatos que aplicaram para a vaga.
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
                width: double.maxFinite, // Para que a lista ocupe o máximo possível
                child: ListView.builder(
                  shrinkWrap: true, // Para que a lista não ocupe espaço desnecessário
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
                                          _acceptApplication(jobId, application.id!, applicantId);
                                          Navigator.of(context).pop(); // Fecha o diálogo
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Aceitar', style: TextStyle(color: branco)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _declineApplication(jobId, application.id!, applicantId);
                                          // Não fecha o diálogo para permitir aceitar outro
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

  /// Aceita uma candidatura e atualiza o status da vaga.
  void _acceptApplication(String jobId, String applicationId, String acceptedByUserId) async {
    try {
      // 1. Atualiza o status da candidatura para 'accepted'
      await _firestore.collection('jobs').doc(jobId).collection('applications').doc(applicationId).update({
        'status': 'accepted',
      });

      // 2. Atualiza a vaga principal para indicar que ela foi aceita e por quem
      await _firestore.collection('jobs').doc(jobId).update({
        'accepted': true,
        'declined': false,
        'acceptedByUserId': acceptedByUserId,
      });

      // 3. Adiciona o jobId à lista de trabalhos concluídos do usuário aceito
      await _firestore.collection('users').doc(acceptedByUserId).update({
        'jobsCompleted': FieldValue.arrayUnion([jobId]),
      });

      // 4. Recusar automaticamente outras candidaturas para esta mesma vaga
      final otherApplications = await _firestore.collection('jobs').doc(jobId).collection('applications').where('status', isEqualTo: 'pending').get();
      for (var doc in otherApplications.docs) {
        if (doc.id != applicationId) { // Garante que não estamos recusando a que acabou de ser aceita
          await doc.reference.update({'status': 'declined'});
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidatura aceita e vaga atribuída!')),
      );
    } catch (e) {
      print('Erro ao aceitar candidatura: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar candidatura: $e')),
      );
    }
  }

  /// Recusa uma candidatura.
  void _declineApplication(String jobId, String applicationId, String declinedByUserId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).collection('applications').doc(applicationId).update({
        'status': 'declined',
      });

      // Remover o jobId da lista de trabalhos aceitos (se já estiver lá)
      await _firestore.collection('users').doc(declinedByUserId).update({
        'jobsCompleted': FieldValue.arrayRemove([jobId]), // Apenas para garantir consistência
      });

      // Verifica se existe alguma outra candidatura pendente. Se não houver, a vaga pode
      // voltar a ser 'aberta' (não accepted e não declined) para novas candidaturas.
      // Ou se já tiver sido aceita, o status da vaga principal não muda.
      final remainingPendingApplications = await _firestore.collection('jobs').doc(jobId).collection('applications').where('status', isEqualTo: 'pending').get();
      final acceptedApplication = await _firestore.collection('jobs').doc(jobId).collection('applications').where('status', isEqualTo: 'accepted').get();

      if (remainingPendingApplications.docs.isEmpty && acceptedApplication.docs.isEmpty) {
        // Se não há mais candidaturas pendentes e nenhuma foi aceita, a vaga volta a estar "aberta"
        await _firestore.collection('jobs').doc(jobId).update({
          'accepted': false,
          'declined': false,
          'acceptedByUserId': null,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidatura recusada.')),
      );
    } catch (e) {
      print('Erro ao recusar candidatura: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao recusar candidatura: $e')),
      );
    }
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
              child: Text('Faça login para ver as vagas.',
                  style: TextStyle(fontSize: 18, color: cinzaEscuro)),
            );
          }

          // Busca o tipo de usuário do Firestore
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
                // Contratante vê TODAS as vagas que ele criou, independentemente do status
                jobStream = _firestore.collection('jobs')
                    .where('createdByUserId', isEqualTo: currentUser.uid)
                    .snapshots();
              } else {
                // Prestador de serviço vê vagas disponíveis para ele aplicar:
                // Aquelas que AINDA NÃO FORAM ACEITAS por NINGUÉM,
                // e NÃO foram criadas por ele mesmo.
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
                                job.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: cinzaEscuro,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                job.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: cinzaEscuro.withOpacity(0.8),
                                ),
                              ),
                              if (job.value != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Valor: R\$ ${job.value!.toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: laranjaVivo,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              // Lógica de exibição de status e botões
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isContratante) ...[
                                    // Lógica para o Contratante
                                    if (job.accepted && job.acceptedByUserId != null)
                                      FutureBuilder<DocumentSnapshot>(
                                        future: _firestore.collection('users').doc(job.acceptedByUserId!).get(),
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
                                        stream: _firestore.collection('jobs').doc(job.id!).collection('applications')
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
                                                onPressed: () => _showApplicantsListDialog(job.id!),
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
                                                onPressed: () => _deleteJob(job.id!),
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
                                    // Lógica para o Prestador
                                    FutureBuilder<QuerySnapshot>(
                                      future: _firestore.collection('jobs').doc(job.id!).collection('applications')
                                          .where('applicantId', isEqualTo: currentUser.uid)
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
                                        if (!job.accepted) {
                                          return Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _applyForJob(job.id!, currentUser.uid),
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