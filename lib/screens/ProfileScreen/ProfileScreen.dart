import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: const Color(0xFFFF6F00),
      ),
      body: StreamBuilder<User?>( // Stream para o estado de autenticação
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authSnapshot.data;

          if (user == null) {
            // Se o usuário não está logado, exibe uma mensagem
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Você não está logado.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Faça login para ver seu perfil.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Se o usuário está logado, agora usamos um StreamBuilder para os dados do Firestore
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(), // <--- Usamos .snapshots() para ouvir em tempo real
            builder: (context, docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (docSnapshot.hasError) {
                print('Erro ao carregar dados do Firestore: ${docSnapshot.error}');
                return Center(child: Text('Erro ao carregar dados: ${docSnapshot.error}'));
              }

              if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
                // Caso o documento do usuário não exista no Firestore
                print('Dados do usuário não encontrados para UID: ${user.uid}');
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber, size: 80, color: Colors.amber),
                      SizedBox(height: 16),
                      Text(
                        'Seu perfil ainda não foi criado.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Por favor, complete seu cadastro.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final userData = docSnapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Foto de perfil
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: userData['photoUrl'] != null &&
                                    userData['photoUrl'].toString().isNotEmpty
                                ? NetworkImage(userData['photoUrl'])
                                : const NetworkImage('https://via.placeholder.com/150'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                final controller = TextEditingController(
                                    text: userData['photoUrl'] ?? '');
                                _showEditDialog(
                                  context: context,
                                  title: 'Editar Foto',
                                  controllers: {'URL da Foto': controller},
                                  onSave: (data) {
                                    _updateUserData(context, user.uid,
                                        {'photoUrl': data['URL da Foto'] ?? ''});
                                  },
                                );
                              },
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFFF6F00),
                                child: Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nome e profissão
                    Text(
                      userData['name'] ?? 'Sem nome',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData['profession'] ?? 'Sem profissão',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Dados pessoais
                    _buildSection(
                      context,
                      title: 'Dados Pessoais e Segurança',
                      icon: Icons.person,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Email', userData['email'] ?? ''),
                          _infoRow('Telefone', userData['phone'] ?? 'Não informado'),
                          _infoRow('Senha', '********'),
                          const SizedBox(height: 8),
                          _editButton(() {
                            _showEditDialog(
                              context: context,
                              title: 'Editar Dados Pessoais',
                              controllers: {
                                'name': TextEditingController(text: userData['name'] ?? ''),
                                'phone': TextEditingController(text: userData['phone'] ?? ''),
                              },
                              onSave: (data) {
                                _updateUserData(context, user.uid, data);
                              },
                            );
                          }),
                        ],
                      ),
                    ),

                    // Informações profissionais
                    _buildSection(
                      context,
                      title: 'Informações Profissionais',
                      icon: Icons.work,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Profissão', userData['profession'] ?? ''),
                          _infoRow('Experiência', userData['experience'] ?? ''),
                          _infoRow('Habilidades', userData['skills'] ?? ''),
                          const SizedBox(height: 8),
                          _editButton(() {
                            _showEditDialog(
                              context: context,
                              title: 'Editar Informações Profissionais',
                              controllers: {
                                'profession': TextEditingController(text: userData['profession'] ?? ''),
                                'experience': TextEditingController(text: userData['experience'] ?? ''),
                                'skills': TextEditingController(text: userData['skills'] ?? ''),
                              },
                              onSave: (data) {
                                _updateUserData(context, user.uid, data);
                              },
                            );
                          }),
                        ],
                      ),
                    ),

                    // Sobre Mim
                    _buildSection(
                      context,
                      title: 'Sobre Mim',
                      icon: Icons.info,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['aboutMe'] ?? 'Sem descrição.',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          _editButton(() {
                            _showEditDialog(
                              context: context,
                              title: 'Editar Sobre Mim',
                              controllers: {
                                'aboutMe': TextEditingController(text: userData['aboutMe'] ?? ''),
                              },
                              onSave: (data) {
                                _updateUserData(context, user.uid, {'aboutMe': data['aboutMe']});
                              },
                            );
                          }),
                        ],
                      ),
                    ),

                    // Exemplo de botão de Logout
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        // O AuthWrapper no main.dart cuidará do redirecionamento
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Sair', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Funções Auxiliares (movidas para fora do build, mas ainda parte da classe para acesso ao context) ---

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

  Widget _editButton(VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Editar'),
      ),
    );
  }

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required Map<String, TextEditingController> controllers,
    required Function(Map<String, dynamic>) onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              children: controllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final data =
                    controllers.map((key, value) => MapEntry(key, value.text.trim()));
                onSave(data);
                Navigator.pop(context); // Fecha o diálogo
                // A tela de perfil será atualizada automaticamente via StreamBuilder
                // assim que o Firestore confirmar a atualização.
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserData(
      BuildContext context, String uid, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso!')),
      );
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar dados: $e')),
      );
    }
  }
}