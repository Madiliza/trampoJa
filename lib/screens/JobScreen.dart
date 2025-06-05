// job_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trampoja_app/models/JobModel.dart';
import 'package:trampoja_app/models/UserModel.dart';

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
        title: _titleController.text,
        description: _descriptionController.text,
        value: jobValue,
        createdByUserId: userId,
        // Novos campos para rastrear aplicações
        appliedByUserId: null,
        isPending: false,
      );

      try {
        await _firestore.collection('jobs').add(newJob.toFirestore());
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

  /// Exclui uma vaga do Firestore.
  void _deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaga excluída com sucesso!')),
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
      await _firestore.collection('jobs').doc(jobId).update({
        'isPending': true,
        'appliedByUserId': prestadorId,
        'accepted': false, // Garante que não está aceita ainda
        'declined': false, // Garante que não está recusada ainda
      });
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

  /// Exibe um diálogo com o perfil do aplicante para o contratante.
  void _showApplicantProfileDialog(String applicantUserId, String jobId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(applicantUserId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Logar o erro para depuração
            print('Erro no FutureBuilder ao carregar perfil: ${snapshot.error}');
            return AlertDialog(
              title: const Text('Erro ao carregar perfil'),
              content: Text('Não foi possível carregar o perfil do aplicante: ${snapshot.error}. Por favor, tente novamente.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            // Logar que o documento não existe
            print('Documento do usuário não encontrado para o ID: $applicantUserId');
            return AlertDialog(
              title: const Text('Perfil Não Encontrado'),
              content: const Text('Não foi possível encontrar os dados do perfil do aplicante.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          }

          // Se chegou aqui, o snapshot tem dados.
          final applicantData = UserModel.fromDocument(snapshot.data!);

          return AlertDialog(
            backgroundColor: branco,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              'Perfil de ${applicantData.name ?? 'Aplicante Desconhecido'}', // Tratamento para nome nulo
              style: const TextStyle(color: cinzaEscuro, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nome: ${applicantData.name ?? 'Não informado'}', style: const TextStyle(color: cinzaEscuro)),
                  const SizedBox(height: 8),
                  Text('Email: ${applicantData.email ?? 'Não informado'}', style: const TextStyle(color: cinzaEscuro)),
                  const SizedBox(height: 8),
                  Text('Tipo de Usuário: ${applicantData.userType ?? 'Não informado'}', style: const TextStyle(color: cinzaEscuro)),
                  // Adicione mais campos do perfil do usuário aqui, se houver
                  // Exemplo:
                  // Text('Telefone: ${applicantData.phoneNumber ?? 'Não informado'}', style: const TextStyle(color: cinzaEscuro)),
                  // Text('Habilidades: ${applicantData.skills?.join(', ') ?? 'Não informado'}', style: const TextStyle(color: cinzaEscuro)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar', style: TextStyle(color: cinzaEscuro)),
              ),
              ElevatedButton(
                onPressed: () {
                  _acceptJob(jobId, applicantUserId);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Aceitar', style: TextStyle(color: branco)),
              ),
              ElevatedButton(
                onPressed: () {
                  _declineJob(jobId, applicantUserId);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Recusar', style: TextStyle(color: branco)),
              ),
            ],
          );
        },
      );
    },
  );
}

  /// Aceita uma vaga pelo contratante.
  void _acceptJob(String jobId, String acceptedByUserId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'accepted': true,
        'declined': false,
        'isPending': false, // Remove o status de pendência
        'acceptedByUserId': acceptedByUserId, // Salva o ID do prestador aceito
        'appliedByUserId': null, // Limpa quem aplicou
      });

      // Opcional: Adicionar o jobId à lista de trabalhos aceitos do usuário (se ainda não estiver lá)
      await _firestore.collection('users').doc(acceptedByUserId).update({
        'jobsCompleted': FieldValue.arrayUnion([jobId]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaga aceita e atribuída ao prestador!')),
      );
    } catch (e) {
      print('Erro ao aceitar vaga: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar vaga: $e')),
      );
    }
  }

  /// Recusa uma vaga pelo contratante.
  void _declineJob(String jobId, String declinedByUserId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'declined': true,
        'accepted': false,
        'isPending': false, // Remove o status de pendência
        'appliedByUserId': null, // Limpa quem aplicou
        // Se quiser rastrear quem recusou: 'declinedByUserId': declinedByUserId,
      });

      // Opcional: Remover o jobId da lista de trabalhos aceitos (se já estiver lá)
      await _firestore.collection('users').doc(declinedByUserId).update({
        'jobsCompleted': FieldValue.arrayRemove([jobId]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidatura recusada.')),
      );
    } catch (e) {
      print('Erro ao recusar vaga: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao recusar vaga: $e')),
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
                // Contratante vê apenas as vagas que ele criou
                jobStream = _firestore.collection('jobs')
                    .where('createdByUserId', isEqualTo: currentUser.uid)
                    .snapshots();
              } else {
                // Prestador de serviço vê todas as vagas que não estão aceitas ou pendentes (para ele)
                jobStream = _firestore.collection('jobs')
                    .where('accepted', isEqualTo: false) // Não aceitas por ninguém
                    .where('isPending', isEqualTo: false) // Não estão pendentes
                    .where('appliedByUserId', isNotEqualTo: currentUser.uid) // Não aplicadas por ele mesmo
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isContratante) ...[
                                    if (job.isPending == true && job.appliedByUserId != null)
                                      ElevatedButton.icon(
                                        onPressed: () => _showApplicantProfileDialog(job.appliedByUserId!, job.id!),
                                        icon: const Icon(Icons.person, color: branco),
                                        label: const Text('Ver Candidato', style: TextStyle(color: branco)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    const SizedBox(width: 10),
                                    if (job.accepted == false && job.isPending == false)
                                      ElevatedButton.icon(
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
                                    if (job.accepted == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                            const SizedBox(width: 5),
                                            const Text(
                                              'Vaga Atribuída!',
                                              style: TextStyle(
                                                color: Color.fromARGB(255, 33, 114, 36),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  if (isPrestador && !job.accepted && !job.isPending)
                                    Expanded(
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
                                    ),
                                  if (isPrestador && job.isPending == true && job.appliedByUserId == currentUser.uid)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time, color: Colors.yellow.shade700, size: 20),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'Candidatura Pendente',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isPrestador && job.accepted && job.acceptedByUserId == currentUser.uid)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'Vaga Aceita!',
                                            style: TextStyle(
                                              color: Color.fromARGB(255, 33, 114, 36),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isPrestador && job.declined && job.appliedByUserId == currentUser.uid)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'Candidatura Recusada!',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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