// profile_screen.dart
import 'dart:io'; // Importe para File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as FBAuth;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importe o Supabase Flutter
import 'package:trampoja_app/models/UserModel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker(); // Instância do ImagePicker
  // Remova: final FirebaseStorage _storage = FirebaseStorage.instance;

  // Instância do cliente Supabase (já inicializado no main.dart)
  final SupabaseClient supabase = Supabase.instance.client;

  // Função para selecionar e fazer upload da imagem para o Supabase Storage
  Future<void> _pickAndUploadImage(String userId) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma imagem selecionada.')),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carregando imagem...')),
        );
      }

      // Gere um nome único para o arquivo
      final String fileName = 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      const String bucketName = 'imagens-do-app'; // Use o nome do seu bucket no Supabase

      // Faça o upload para o Supabase Storage
      final String path = await supabase.storage
          .from(bucketName)
          .upload(
            fileName,
            File(image.path),
            fileOptions: const FileOptions(
              cacheControl: '3600', // Cache por 1 hora
              upsert: true, // Substitui o arquivo se já existir com o mesmo nome
              contentType: 'image/jpeg', // Tipo de conteúdo da imagem
            ),
          );

      // Obtenha a URL pública do arquivo (se o bucket for público ou tiver política de SELECT)
      final String downloadUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(path); // 'path' aqui é o fileName usado no upload

      if (mounted) {
        await _updateUserData(context, userId, {'photoUrl': downloadUrl});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')),
        );
      }
    } on StorageException catch (e) {
      print('Erro no upload para Supabase Storage: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no upload da imagem: ${e.message}')),
        );
      }
    } catch (e) {
      print('Erro inesperado ao selecionar/enviar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar a foto de perfil: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: const Color(0xFFFF6F00),
      ),
      body: StreamBuilder<FBAuth.User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authSnapshot.data;

          if (user == null) {
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

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
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

              final userData = UserModel.fromDocument(docSnapshot.data!);
              final isPrestador = userData.userType == 'prestador';

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
                            backgroundImage: userData.photoUrl.isNotEmpty
                                ? NetworkImage(userData.photoUrl)
                                : const NetworkImage('https://via.placeholder.com/150'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () => _pickAndUploadImage(user.uid), // Chamada da nova função
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

                    // Dados pessoais (para ambos)
                    _buildSection(
                      context,
                      title: 'Dados Pessoais e Segurança',
                      icon: Icons.person,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Email', userData.email),
                          _infoRow('Telefone', userData.phone),
                          _infoRow('Senha', '********'),
                          const SizedBox(height: 8),
                          _editButton(() {
                            _showEditDialog(
                              context: context,
                              title: 'Editar Dados Pessoais',
                              controllers: {
                                'name': TextEditingController(text: userData.name),
                                'phone': TextEditingController(text: userData.phone),
                              },
                              onSave: (data) {
                                _updateUserData(context, user.uid, data);
                              },
                            );
                          }),
                        ],
                      ),
                    ),

                    // Informações profissionais (apenas para prestadores)
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
                            const SizedBox(height: 8),
                            _editButton(() {
                              _showEditDialog(
                                context: context,
                                title: 'Editar Informações Profissionais',
                                controllers: {
                                  'profession': TextEditingController(text: userData.profession),
                                  'experience': TextEditingController(text: userData.experience),
                                  'skills': TextEditingController(text: userData.skills),
                                },
                                onSave: (data) {
                                  _updateUserData(context, user.uid, data);
                                },
                              );
                            }),
                          ],
                        ),
                      ),

                    // Sobre Mim (para ambos)
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
                          const SizedBox(height: 8),
                          _editButton(() {
                            _showEditDialog(
                              context: context,
                              title: 'Editar Sobre Mim',
                              controllers: {
                                'aboutMe': TextEditingController(text: userData.aboutMe),
                              },
                              onSave: (data) {
                                _updateUserData(context, user.uid, {'aboutMe': data['aboutMe']});
                              },
                            );
                          }),
                        ],
                      ),
                    ),

                    // Trabalhos Aceitos (apenas para prestadores)
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
                              ...userData.jobsCompleted.map((jobId) => _buildJobAcceptedItem(jobId, context)),
                            const SizedBox(height: 8),
                            // Você pode adicionar um botão aqui para ver mais detalhes ou gerenciar trabalhos
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
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
        child: const Text('Editar', style: TextStyle(color: Colors.white)), // Corrigido para texto branco
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
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserData(BuildContext context, String userId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso!')),
        );
      }
    } catch (e) {
      print('Erro ao atualizar dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar dados: $e')),
        );
      }
    }
  }

  // Novo widget para exibir itens de trabalhos aceitos (apenas para prestadores)
  Widget _buildJobAcceptedItem(String jobId, BuildContext context) {
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