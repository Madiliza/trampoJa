import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/screens/ProfileScreen/dialogs/edit_profile_dialog.dart';
import 'package:trampoja_app/screens/ProfileScreen/widgets/accepted_jobs_list.dart';
import 'package:trampoja_app/screens/ProfileScreen/widgets/info_row.dart';
import 'package:trampoja_app/screens/ProfileScreen/widgets/profile_avatar_editor.dart';
import 'package:trampoja_app/screens/ProfileScreen/widgets/profile_section_card.dart';
import 'package:trampoja_app/services/user_service.dart'; // Importe o serviço
import 'package:trampoja_app/utils/app_colors.dart'; // Importe as cores


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService(); // Instância do serviço

  Future<void> _updateUserData(
      BuildContext context, String userId, Map<String, dynamic> data) async {
    try {
      await _userService.updateUserData(userId, data);
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

  void _showEditProfileDialog({
    required BuildContext context,
    required String title,
    required Map<String, TextEditingController> controllers,
    required Function(Map<String, dynamic>) onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return EditProfileDialog(
          title: title,
          controllers: controllers,
          onSave: onSave,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(color: branco)),
        backgroundColor: laranjaVivo,
      ),
      body: StreamBuilder<User?>(
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber, size: 80, color: Colors.amber),
                      const SizedBox(height: 16),
                      const Text(
                        'Seu perfil ainda não foi criado.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Por favor, complete seu cadastro.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        icon: const Icon(Icons.logout, color: branco),
                        label: const Text('Sair', style: TextStyle(color: branco)),
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
              }

              final userData = UserModel.fromDocument(docSnapshot.data!);
              final isPrestador = userData.userType == 'prestador';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ProfileAvatarEditor(
                      photoUrl: userData.photoUrl,
                      onEditPressed: () =>
                          _userService.pickAndUploadProfileImage(user.uid, context),
                    ),
                    const SizedBox(height: 16),

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

                    ProfileSectionCard(
                      title: 'Dados Pessoais e Segurança',
                      icon: Icons.person,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoRow(label: 'Email', value: userData.email),
                          InfoRow(label: 'Telefone', value: userData.phone),
                          const InfoRow(label: 'Senha', value: '********'),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                _showEditProfileDialog(
                                  context: context,
                                  title: 'Editar Dados Pessoais',
                                  controllers: {
                                    'name': TextEditingController(text: userData.name),
                                    'phone': TextEditingController(text: userData.phone),
                                    // Note: Email and Password are not directly editable via text fields here for security
                                  },
                                  onSave: (data) {
                                    _updateUserData(context, user.uid, data);
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Editar', style: TextStyle(color: branco)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isPrestador)
                      ProfileSectionCard(
                        title: 'Informações Profissionais',
                        icon: Icons.work,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoRow(label: 'Profissão', value: userData.profession),
                            InfoRow(label: 'Experiência', value: userData.experience),
                            InfoRow(label: 'Habilidades', value: userData.skills),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showEditProfileDialog(
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
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Editar', style: TextStyle(color: branco)),
                              ),
                            ),
                          ],
                        ),
                      ),

                    ProfileSectionCard(
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                _showEditProfileDialog(
                                  context: context,
                                  title: 'Editar Sobre Mim',
                                  controllers: {
                                    'aboutMe': TextEditingController(text: userData.aboutMe),
                                  },
                                  onSave: (data) {
                                    _updateUserData(context, user.uid, {'aboutMe': data['aboutMe']});
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Editar', style: TextStyle(color: branco)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isPrestador)
                      ProfileSectionCard(
                        title: 'Trabalhos Aceitos',
                        icon: Icons.assignment_turned_in,
                        content: AcceptedJobsList(jobIds: userData.jobsCompleted),
                      ),

                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout, color: branco),
                      label: const Text('Sair', style: TextStyle(color: branco)),
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
}