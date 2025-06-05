import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/screens/ProfileScreen/dialogs/edit_profile_dialog.dart';
import 'package:trampoja_app/screens/ProfileScreen/widgets/accepted_jobs_list.dart';
import 'package:trampoja_app/screens/ProfileScreen/widgets/info_row.dart';
import 'package:trampoja_app/screens/ProfileScreen/widgets/profile_avatar_editor.dart';
import 'package:trampoja_app/screens/ProfileScreen/widgets/profile_section_card.dart';
import 'package:trampoja_app/services/user_service.dart';
import 'package:trampoja_app/utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  Future<void> _updateUserData(
      BuildContext context, String userId, Map<String, dynamic> data) async {
    try {
      await _userService.updateUserData(userId, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados com sucesso!', style: TextStyle(color: branco)),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
      }
    } catch (e) {
      print('Erro ao atualizar dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar dados: $e', style: const TextStyle(color: branco)),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
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

  // --- Função para mostrar o menu de configurações ---
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Permite bordas arredondadas e sombra
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: branco,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Cantos arredondados no topo
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                spreadRadius: 2.0,
                offset: Offset(0.0, -5.0), // Sombra para cima
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ocupa o mínimo de espaço necessário
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const Text(
                'Configurações do Perfil',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColorPrimary,
                ),
              ),
              const Divider(height: 24, thickness: 1, color: borderColor),
              _buildSettingsOption(
                context,
                icon: Icons.notifications,
                text: 'Notificações',
                onTap: () {
                  Navigator.pop(context); // Fecha o BottomSheet
                  // TODO: Implementar navegação para tela de Notificações
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navegar para Notificações')),
                  );
                },
              ),
              _buildSettingsOption(
                context,
                icon: Icons.privacy_tip,
                text: 'Privacidade e Segurança',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementar navegação para tela de Privacidade
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navegar para Privacidade e Segurança')),
                  );
                },
              ),
              _buildSettingsOption(
                context,
                icon: Icons.help_outline,
                text: 'Ajuda e Suporte',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementar navegação para tela de Ajuda
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navegar para Ajuda e Suporte')),
                  );
                },
              ),
              _buildSettingsOption(
                context,
                icon: Icons.logout,
                text: 'Sair da Conta',
                textColor: errorColor, // Cor de destaque para sair
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // --- Widget auxiliar para opções do menu de configurações ---
  Widget _buildSettingsOption(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10), // Efeito de toque arredondado
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? textColorPrimary, size: 24),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 17,
                color: textColor ?? textColorPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(), // Empurra o resto para a direita
            Icon(Icons.arrow_forward_ios, color: textColor ?? textColorSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(
            color: branco,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        // --- Adiciona o IconButton para configurações na AppBar ---
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: branco, size: 26),
            tooltip: 'Configurações',
            onPressed: () => _showSettingsMenu(context), // Chama a função do menu
          ),
          const SizedBox(width: 8), // Espaçamento extra à direita
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final user = authSnapshot.data;

          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 100, color: textColorSecondary.withOpacity(0.6)),
                    const SizedBox(height: 24),
                    const Text(
                      'Você não está logado.',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColorPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Faça login para ver seu perfil e acessar todas as funcionalidades.',
                      style: TextStyle(fontSize: 16, color: textColorSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }

              if (docSnapshot.hasError) {
                print('Erro ao carregar dados do Firestore: ${docSnapshot.error}');
                return Center(child: Text('Erro ao carregar dados: ${docSnapshot.error}', style: const TextStyle(color: errorColor)));
              }

              if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
                print('Dados do usuário não encontrados para UID: ${user.uid}');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber, size: 100, color: Colors.amber.shade700),
                        const SizedBox(height: 24),
                        const Text(
                          'Seu perfil ainda não foi criado.',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColorPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Por favor, complete seu cadastro para continuar.',
                          style: TextStyle(fontSize: 16, color: textColorSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          icon: const Icon(Icons.logout, color: branco, size: 20),
                          label: const Text('Sair', style: TextStyle(color: branco, fontSize: 16, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorColor,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final userData = UserModel.fromDocument(docSnapshot.data!);
              final isPrestador = userData.userType == 'prestador';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ProfileAvatarEditor(
                      photoUrl: userData.photoUrl,
                      onEditPressed: () =>
                          _userService.pickAndUploadProfileImage(user.uid, context),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      userData.name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColorPrimary),
                    ),
                    const SizedBox(height: 8),
                    if (isPrestador && userData.profession.isNotEmpty)
                      Text(
                        userData.profession,
                        style: const TextStyle(fontSize: 18, color: textColorSecondary),
                      ),
                    const SizedBox(height: 32),

                    ProfileSectionCard(
                      title: 'Dados Pessoais e Segurança',
                      icon: Icons.person,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoRow(label: 'Email', value: userData.email),
                          InfoRow(label: 'Telefone', value: userData.phone.isNotEmpty ? userData.phone : 'Não informado'),
                          const InfoRow(label: 'Senha', value: '********'),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showEditProfileDialog(
                                  context: context,
                                  title: 'Editar Dados Pessoais',
                                  controllers: {
                                    'name': TextEditingController(text: userData.name),
                                    'telefone': TextEditingController(text: userData.phone),
                                  },
                                  onSave: (data) {
                                    _updateUserData(context, user.uid, data);
                                  },
                                );
                              },
                              icon: const Icon(Icons.edit, color: branco, size: 18),
                              label: const Text('Editar', style: TextStyle(color: branco, fontSize: 15, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isPrestador)
                      ProfileSectionCard(
                        title: 'Informações Profissionais',
                        icon: Icons.work,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoRow(label: 'Profissão', value: userData.profession.isNotEmpty ? userData.profession : 'Não informada'),
                            InfoRow(label: 'Experiência', value: userData.experience.isNotEmpty ? userData.experience : 'Não informada'),
                            InfoRow(label: 'Habilidades', value: userData.skills.isNotEmpty ? userData.skills : 'Não informadas'),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showEditProfileDialog(
                                    context: context,
                                    title: 'Editar Informações Profissionais',
                                    controllers: {
                                      'profissão': TextEditingController(text: userData.profession),
                                      'experiencia': TextEditingController(text: userData.experience),
                                      'habilidades': TextEditingController(text: userData.skills),
                                    },
                                    onSave: (data) {
                                      _updateUserData(context, user.uid, data);
                                    },
                                  );
                                },
                                icon: const Icon(Icons.edit, color: branco, size: 18),
                                label: const Text('Editar', style: TextStyle(color: branco, fontSize: 15, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isPrestador) const SizedBox(height: 16),

                    ProfileSectionCard(
                      title: 'Sobre Mim',
                      icon: Icons.info_outline,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData.aboutMe.isNotEmpty ? userData.aboutMe : 'Nenhuma descrição sobre você ainda.',
                            style: const TextStyle(fontSize: 15, color: textColorPrimary, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showEditProfileDialog(
                                  context: context,
                                  title: 'Editar Sobre Mim',
                                  controllers: {
                                    'fale um pouco sobre você': TextEditingController(text: userData.aboutMe),
                                  },
                                  onSave: (data) {
                                    _updateUserData(context, user.uid, {'aboutMe': data['aboutMe']});
                                  },
                                );
                              },
                              icon: const Icon(Icons.edit, color: branco, size: 18),
                              label: const Text('Editar', style: TextStyle(color: branco, fontSize: 15, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isPrestador)
                      ProfileSectionCard(
                        title: 'Trabalhos Concluídos',
                        icon: Icons.assignment_turned_in,
                        content: AcceptedJobsList(jobIds: userData.jobsCompleted),
                      ),
                    if (isPrestador) const SizedBox(height: 16),

                    // O botão "Sair da Conta" agora pode ser o último elemento, se não for movido para o menu de configurações.
                    // Se a opção "Sair da Conta" for colocada no BottomSheet de configurações, você pode remover este botão principal.
                    // Mantenho-o aqui por enquanto, mas ele está também no BottomSheet.
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout, color: branco, size: 20),
                      label: const Text('Sair da Conta', style: TextStyle(color: branco, fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                    ),
                    const SizedBox(height: 20),
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