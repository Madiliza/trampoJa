// view_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trampoja_app/models/UserModel.dart';

class ViewProfileScreen extends StatelessWidget {
  final String userId;

  const ViewProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        backgroundColor: const Color(0xFFFF6F00),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, docSnapshot) {
          if (docSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (docSnapshot.hasError) {
            print('Erro ao carregar dados do Firestore: ${docSnapshot.error}');
            return Center(child: Text('Erro ao carregar dados: ${docSnapshot.error}'));
          }

          if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
            print('Dados do usuário não encontrados para UID: $userId');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Perfil não encontrado.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Este usuário pode não ter um perfil público.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final userData = UserModel.fromDocument(docSnapshot.data!);
          final isPrestador = userData.userType == 'prestador';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Foto de perfil
                Center(
                  // A tag do Hero precisa ser única para cada CircleAvatar que pode estar animando.
                  // Usar o userId garante essa unicidade.
                  child: Hero(
                    tag: 'profile_picture_$userId', // Tag única para este perfil
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: userData.photoUrl.isNotEmpty
                          ? NetworkImage(userData.photoUrl) // Carrega a URL do Supabase
                          // Placeholder se a foto não estiver disponível
                          : const NetworkImage('https://via.placeholder.com/150/0000FF/FFFFFF?text=Sem+Foto'), // Placeholder com texto
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nome e profissão (profissão só para prestador)
                Text(
                  userData.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (isPrestador && userData.profession.isNotEmpty)
                  Text(
                    userData.profession,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                const SizedBox(height: 24),

                // Dados pessoais (para ambos) - Somente visualização
                _buildSection(
                  context,
                  title: 'Dados Pessoais',
                  icon: Icons.person,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Email', userData.email),
                      _infoRow('Telefone', userData.phone),
                    ],
                  ),
                ),

                // Informações profissionais (apenas para prestadores) - Somente visualização
                if (isPrestador)
                  _buildSection(
                    context,
                    title: 'Informações Profissionais',
                    icon: Icons.work,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Profissão', userData.profession),
                        _infoRow('Experiência', userData.experience),
                        _infoRow('Habilidades', userData.skills),
                      ],
                    ),
                  ),

                // Sobre Mim (para ambos) - Somente visualização
                _buildSection(
                  context,
                  title: 'Sobre Mim',
                  icon: Icons.info,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData.aboutMe.isNotEmpty ? userData.aboutMe : 'Sem descrição.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Trabalhos Aceitos (apenas para prestadores) - Somente visualização
                if (isPrestador)
                  _buildSection(
                    context,
                    title: 'Trabalhos Aceitos',
                    icon: Icons.assignment_turned_in,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (userData.jobsCompleted.isEmpty)
                          const Text('Nenhum trabalho aceito ainda.',
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic))
                        else
                          // Usar .toList() é uma boa prática para iteradores em widgets
                          ...userData.jobsCompleted.map((jobId) => _buildJobAcceptedItem(jobId)).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Funções Auxiliares (adaptadas para visualização) ---

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
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
          print('Erro ao carregar trabalho $jobId: ${snapshot.error}');
          return Text('Erro ao carregar trabalho: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          print('Trabalho $jobId não encontrado no Firestore.');
          return const Text('Trabalho não encontrado.');
        }

        final Map<String, dynamic>? jobData = snapshot.data!.data() as Map<String, dynamic>?;

        if (jobData == null) {
          print('Dados do trabalho $jobId são nulos.');
          return const Text('Dados do trabalho são nulos.');
        }

        final String jobTitle = (jobData['title'] as String?) ?? 'Título indisponível';
        final num? jobValueNum = jobData['value'] as num?;
        final String jobValue = jobValueNum != null
            ? 'R\$ ${jobValueNum.toStringAsFixed(2).replaceAll('.', ',')}'
            : 'Valor indisponível';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(jobValue),
            ],
          ),
        );
      },
    );
  }
}