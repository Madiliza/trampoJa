// view_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trampoja_app/models/UserModel.dart'; // Certifique-se de que este modelo corretamente lida com dados do Firestore
import 'package:trampoja_app/utils/app_colors.dart'; // Importe suas cores personalizadas

class ViewProfileScreen extends StatelessWidget {
  final String userId;

  const ViewProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil do Usuário',
          style: TextStyle(color: branco),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: branco),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, docSnapshot) {
          // 1. Estado de Carregamento
          if (docSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          // 2. Tratamento de Erros da Conexão
          if (docSnapshot.hasError) {
            print('Erro ao carregar dados do Firestore: ${docSnapshot.error}');
            return Center(
              child: Text(
                'Erro ao carregar dados: ${docSnapshot.error}',
                style: const TextStyle(color: errorColor),
                textAlign: TextAlign.center,
              ),
            );
          }

          // 3. Tratamento de Dados Ausentes, Inexistentes ou Nulos
          // Se o documento não existe ou não tem dados, ou os dados são nulos.
          if (!docSnapshot.hasData || !docSnapshot.data!.exists || docSnapshot.data!.data() == null) {
            print('Dados do usuário não encontrados ou nulos para UID: ${userId ?? 'N/A'}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 100, color: textColorSecondary.withOpacity(0.6)),
                    const SizedBox(height: 24),
                    const Text(
                      'Perfil não encontrado ou incompleto.', // Mensagem mais descritiva
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColorPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Este usuário pode não ter um perfil público ou ainda não ter completado o cadastro.',
                      style: TextStyle(fontSize: 16, color: textColorSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Processamento dos Dados do Documento (Tente de forma segura)
          // Usamos try-catch para capturar erros durante a conversão do DocumentSnapshot
          // para o UserModel e a construção da UI que o utiliza.
          try {
            final userData = UserModel.fromDocument(docSnapshot.data!);
            final isPrestador = userData.userType == 'prestador';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- Seção da Foto de Perfil (SEM HERO AQUI) ---
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200], // Cor de fundo do avatar
                      backgroundImage: userData.photoUrl.isNotEmpty
                          ? NetworkImage(userData.photoUrl) as ImageProvider
                          : null, // Sem backgroundImage se a URL vazia
                      child: userData.photoUrl.isEmpty
                          ? Icon(Icons.person, size: 60, color: Colors.grey[600]) // Fallback para um ícone
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nome e Profissão
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

                  // --- Dados Pessoais ---
                  _buildSection(
                    context,
                    title: 'Dados Pessoais',
                    icon: Icons.person,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Email', userData.email),
                        _infoRow('Telefone', userData.phone.isNotEmpty ? userData.phone : 'Não informado'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Informações Profissionais (apenas para prestadores) ---
                  if (isPrestador) ...[
                    _buildSection(
                      context,
                      title: 'Informações Profissionais',
                      icon: Icons.work,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Profissão', userData.profession.isNotEmpty ? userData.profession : 'Não informado'),
                          _infoRow('Experiência', userData.experience.isNotEmpty ? userData.experience : 'Não informado'),
                          _infoRow('Habilidades', userData.skills.isNotEmpty ? userData.skills : 'Não informado'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Sobre Mim ---
                  _buildSection(
                    context,
                    title: 'Sobre Mim',
                    icon: Icons.info_outline,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData.aboutMe.isNotEmpty ? userData.aboutMe : 'Nenhuma descrição sobre o usuario ainda.',
                          style: const TextStyle(fontSize: 15, color: textColorPrimary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Trabalhos Concluídos (apenas para prestadores) ---
                  if (isPrestador)
                    _buildSection(
                      context,
                      title: 'Trabalhos Concluídos',
                      icon: Icons.assignment_turned_in,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (userData.jobsCompleted.isEmpty)
                            const Text(
                              'Nenhum trabalho concluído ainda.',
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: textColorSecondary),
                            )
                          else
                            ...userData.jobsCompleted.map((jobId) => _buildJobAcceptedItem(jobId)).toList(),
                        ],
                      ),
                    ),
                  if (isPrestador) const SizedBox(height: 20),
                ],
              ),
            );
          } catch (e) {
            // Se houver um erro ao parsear UserModel ou construir a UI, capture-o aqui.
            print('Erro FATAL ao processar dados ou construir UI: $e');
            // Logar os dados brutos do Firestore para depuração
            if (docSnapshot.data != null && docSnapshot.data!.data() != null) {
              print('Dados brutos do Firestore (para depuração): ${docSnapshot.data!.data()}');
            } else {
              print('Dados brutos do Firestore eram nulos ou inexistentes após conexão.');
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: errorColor),
                    const SizedBox(height: 24),
                    Text(
                      'Não foi possível exibir este perfil devido a um erro de dados.',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Detalhes do erro: $e', // Mostra o erro para depuração
                      style: const TextStyle(fontSize: 14, color: textColorSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // --- Funções Auxiliares (Helper Functions) ---

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: laranjaVivo, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColorPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: borderColor),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: textColorPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: textColorSecondary),
            ),
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
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: LinearProgressIndicator(color: primaryColor),
          );
        }
        if (snapshot.hasError) {
          print('Erro ao carregar trabalho $jobId: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('Erro ao carregar trabalho: ${snapshot.error}', style: const TextStyle(color: errorColor)),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          print('Trabalho $jobId não encontrado no Firestore.');
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Text('Trabalho não encontrado.', style: TextStyle(fontStyle: FontStyle.italic, color: textColorSecondary)),
          );
        }

        final Map<String, dynamic>? jobData = snapshot.data!.data() as Map<String, dynamic>?;

        if (jobData == null) {
          print('Dados do trabalho $jobId são nulos.');
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Text('Dados do trabalho são nulos.', style: TextStyle(fontStyle: FontStyle.italic, color: errorColor)),
          );
        }

        final String jobTitle = (jobData['title'] as String?) ?? 'Título indisponível';
        final num? jobValueNum = jobData['value'] as num?;
        final String jobValue = jobValueNum != null
            ? 'R\$ ${jobValueNum.toStringAsFixed(2).replaceAll('.', ',')}'
            : 'Valor indisponível';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    jobTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColorPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  jobValue,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: accentColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}