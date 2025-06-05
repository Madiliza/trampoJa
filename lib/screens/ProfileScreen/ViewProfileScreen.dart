// view_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trampoja_app/models/UserModel.dart'; // Certifique-se de que este caminho está correto

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
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: userData.photoUrl.isNotEmpty
                        ? NetworkImage(userData.photoUrl)
                        : const NetworkImage('https://via.placeholder.com/150'),
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
                          ...userData.jobsCompleted.map((jobId) => _buildJobAcceptedItem(jobId)),
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

  // Novo widget para exibir itens de trabalhos aceitos (apenas para prestadores)
  Widget _buildJobAcceptedItem(String jobId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Erro ao carregar trabalho: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Trabalho não encontrado.');
        }

        final jobData = snapshot.data!.data() as Map<String, dynamic>;
        final jobTitle = jobData['title'] ?? 'Título indisponível';
        final jobValue = (jobData['value'] as num?)?.toStringAsFixed(2).replaceAll('.', ',');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (jobValue != null) Text('R\$ $jobValue'),
            ],
          ),
        );
      },
    );
  }
}