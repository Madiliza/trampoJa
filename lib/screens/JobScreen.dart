// job_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar FirebaseAuth
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
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instância do FirebaseAuth

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
        createdByUserId: userId, // Salva o UID do criador da vaga
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
              onPressed: () => _addJob(userId), // Passa o userId para _addJob
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

  /// Aceita uma vaga e adiciona o ID da vaga aos 'jobsCompleted' do usuário prestador.
  void _acceptJob(String jobId, String userId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'accepted': true,
        'declined': false,
        'acceptedByUserId': userId, // Salva quem aceitou a vaga
      });

      // Adiciona o jobId à lista de trabalhos aceitos do usuário
      await _firestore.collection('users').doc(userId).update({
        'jobsCompleted': FieldValue.arrayUnion([jobId]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaga aceita com sucesso!')),
      );
    } catch (e) {
      print('Erro ao aceitar vaga: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar vaga: $e')),
      );
    }
  }

  /// Recusa uma vaga.
  void _declineJob(String jobId, String userId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'declined': true,
        'accepted': false,
        // Você pode adicionar um campo 'declinedByUserId' se quiser rastrear quem recusou.
      });

      // Remove o jobId da lista de trabalhos aceitos (se já estiver lá e for recusado)
      await _firestore.collection('users').doc(userId).update({
        'jobsCompleted': FieldValue.arrayRemove([jobId]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaga recusada com sucesso!')),
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
                // Prestador de serviço vê todas as vagas
                jobStream = _firestore.collection('jobs').snapshots();
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
                        color: pessegoClaro,
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
                                  if (isContratante)
                                    ElevatedButton.icon(
                                      onPressed: () => _deleteJob(job.id!), // Botão de excluir para contratantes
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
                                  if (isPrestador && !job.accepted && !job.declined)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _acceptJob(job.id!, currentUser.uid),
                                        icon: const Icon(Icons.check, color: branco),
                                        label: const Text('Aceitar', style: TextStyle(color: branco)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: laranjaVivo,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  if (isPrestador && !job.accepted && !job.declined)
                                    const SizedBox(width: 10),
                                  if (isPrestador && !job.accepted && !job.declined)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _declineJob(job.id!, currentUser.uid),
                                        icon: const Icon(Icons.close, color: cinzaEscuro),
                                        label: const Text('Recusar', style: TextStyle(color: cinzaEscuro)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: laranjaSuave,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  if (isPrestador && job.accepted)
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
                                          Text(
                                            'Vaga Aceita!',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isPrestador && job.declined)
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
                                          Text(
                                            'Vaga Recusada!',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
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
            return Container(); // Ou um CircularProgressIndicator pequeno
          }
          final currentUser = authSnapshot.data;
          if (currentUser == null) {
            return Container();
          }

          // Busca o tipo de usuário para decidir se exibe o FAB
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
                  onPressed: () => _showCreateJobDialog(currentUser.uid), // Passa o UID do usuário
                  backgroundColor: laranjaVivo,
                  child: const Icon(Icons.add, color: branco),
                );
              } else {
                return Container(); // Não exibe o botão para prestadores
              }
            },
          );
        },
      ),
    );
  }
}