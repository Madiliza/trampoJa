// lib/screens/jobScreen/widgets/job_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trampoja_app/models/JobModel.dart';
import 'package:trampoja_app/models/UserModel.dart';
import 'package:trampoja_app/models/ApplicationModel.dart';
import 'package:trampoja_app/screens/jobScreen/dialogs/applicant_list_dialog.dart';
import 'package:trampoja_app/utils/app_colors.dart';
import 'package:trampoja_app/services/job_service.dart';

class JobCard extends StatefulWidget {
  final Job job;
  final UserModel currentUserData;
  final User currentUser;
  final Function(String jobId) onDeleteJob; // Callback para excluir vaga

  const JobCard({
    super.key,
    required this.job,
    required this.currentUserData,
    required this.currentUser,
    required this.onDeleteJob,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  final JobService _jobService = JobService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estado local para controlar o carregamento do botão de candidatar
  bool _isApplying = false;

  /// Função para aplicar para vaga (agora usa o JobService)
  void _applyForJob() async {
    // Define o estado para mostrar o indicador de carregamento
    setState(() {
      _isApplying = true;
    });

    try {
      await _jobService.applyForJob(widget.job.id!, widget.currentUser.uid);
      if (!mounted) return; // Verifica se o widget ainda está montado

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Candidatura enviada com sucesso! Aguardando aprovação do contratante.', style: TextStyle(color: branco)),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );

    } on FirebaseException catch (e) { // Captura erros específicos do Firebase
      print('Erro Firebase ao aplicar para vaga: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aplicar para vaga: ${e.message}', style: const TextStyle(color: branco)),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );
    } catch (e) {
      print('Erro inesperado ao aplicar para vaga: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado ao aplicar para vaga: $e', style: const TextStyle(color: branco)),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );
    } finally {
      // Garante que o estado de carregamento seja desativado, independente de sucesso ou erro
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  /// Novo método para exibir o diálogo de candidatos
  void _showApplicantsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ApplicantListDialog(jobId: widget.job.id!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isContratante = widget.currentUserData.userType == 'contratante';
    final isPrestador = widget.currentUserData.userType == 'prestador';

    return Card(
      color: cardColor, // Usando sua cor de cartão
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
              widget.job.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColorPrimary, // Usando sua cor de texto primária
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.job.description,
              style: TextStyle(
                fontSize: 16,
                color: textColorSecondary, // Usando sua cor de texto secundária
              ),
            ),
            if (widget.job.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Valor: R\$ ${widget.job.value!.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor, // Usando sua accentColor para o valor
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // --- Lógica para Contratante ---
                if (isContratante) ...[
                  if (widget.job.accepted && widget.job.acceptedByUserId != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(widget.job.acceptedByUserId!).get(),
                      builder: (context, acceptedSnapshot) {
                        if (acceptedSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator(color: primaryColor);
                        }
                        if (acceptedSnapshot.hasError || !acceptedSnapshot.hasData || !acceptedSnapshot.data!.exists) {
                          return const Text('Prestador aceito não encontrado', style: TextStyle(color: errorColor));
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
                                    style: TextStyle(
                                      color: Colors.green.shade800,
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
                      stream: _firestore.collection('jobs').doc(widget.job.id!).collection('applications')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, applicationsSnapshot) {
                        if (applicationsSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator(color: primaryColor);
                        }
                        if (applicationsSnapshot.hasError) {
                          return Text('Erro: ${applicationsSnapshot.error}', style: const TextStyle(color: errorColor));
                        }

                        // Verificação para `snapshot.data` e `docs` não serem nulos
                        final pendingApplications = applicationsSnapshot.hasData && applicationsSnapshot.data!.docs.isNotEmpty
                            ? applicationsSnapshot.data!.docs.length
                            : 0;

                        if (pendingApplications > 0) {
                          return Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showApplicantsDialog,
                              icon: const Icon(Icons.group, color: branco),
                              label: Text('Ver Candidatos ($pendingApplications)', style: const TextStyle(color: branco)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor, // Usando sua primaryColor
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
                              onPressed: () => widget.onDeleteJob(widget.job.id!),
                              icon: const Icon(Icons.delete, color: branco),
                              label: const Text('Excluir', style: TextStyle(color: branco)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: errorColor, // Usando sua errorColor
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
                // --- Lógica para Prestador ---
                if (isPrestador && !widget.job.accepted) ...[ // Só mostra para prestador se a vaga não estiver aceita
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore.collection('jobs').doc(widget.job.id!).collection('applications')
                        .where('applicantId', isEqualTo: widget.currentUser.uid)
                        .get(),
                    builder: (context, myApplicationSnapshot) {
                      if (myApplicationSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: primaryColor);
                      }
                      if (myApplicationSnapshot.hasError) {
                        return Text('Erro ao carregar sua candidatura: ${myApplicationSnapshot.error}', style: const TextStyle(color: errorColor));
                      }

                      // Verificação para `snapshot.data` e `docs` não serem nulos
                      final myApplications = myApplicationSnapshot.hasData && myApplicationSnapshot.data!.docs.isNotEmpty
                          ? myApplicationSnapshot.data!.docs
                          : [];
                      final hasApplied = myApplications.isNotEmpty;
                      final myApplication = hasApplied ? Application.fromFirestore(myApplications.first) : null;

                      if (hasApplied) {
                        Color statusColor;
                        String statusText;
                        IconData statusIcon;

                        if (myApplication!.status == 'accepted') {
                          statusColor = Colors.green.shade100;
                          statusText = 'Sua Candidatura Aceita!';
                          statusIcon = Icons.check_circle;
                        } else if (myApplication.status == 'pending') {
                          statusColor = Colors.yellow.shade100;
                          statusText = 'Sua Candidatura Pendente';
                          statusIcon = Icons.access_time;
                        } else { // 'declined'
                          statusColor = Colors.red.shade100;
                          statusText = 'Sua Candidatura Recusada!';
                          statusIcon = Icons.cancel;
                        }

                        return Expanded( // Wrap with Expanded to take available space
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor.darken(50), size: 20), // Use darken para uma cor mais escura do ícone
                                const SizedBox(width: 5),
                                Flexible( // Adicionado Flexible para lidar com textos longos
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor.darken(50), // Use darken para uma cor de texto mais escura
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis, // Para evitar overflow de texto
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // Se não aplicou e a vaga não está aceita por ninguém, pode aplicar
                        return Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isApplying ? null : _applyForJob, // Desabilita o botão durante o carregamento
                            icon: _isApplying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: branco,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send, color: branco),
                            label: _isApplying
                                ? const Text('Candidatando...', style: TextStyle(color: branco))
                                : const Text('Candidatar-se', style: TextStyle(color: branco)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor, // Usando sua accentColor
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
                ] else if (isPrestador && widget.job.accepted) ...[ // Se for prestador e a vaga já foi aceita por outro
                  // Mostra que a vaga já foi atribuída
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade700, size: 20),
                        const SizedBox(width: 5),
                        const Text('Vaga Atribuída a Outro Prestador', style: TextStyle(color: cinzaEscuro, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extensão para escurecer a cor, útil para ícones e textos de status.
extension ColorExtension on Color {
  Color darken([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    final f = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }
}