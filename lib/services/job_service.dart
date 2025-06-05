// lib/services/job_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trampoja_app/models/JobModel.dart';
import 'package:trampoja_app/models/ApplicationModel.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adiciona uma nova vaga à coleção 'jobs' no Firestore.
  Future<void> addJob({
    required String title,
    required String description,
    double? value,
    required String createdByUserId,
  }) async {
    // Gera um ID antes de adicionar para usá-lo no documento
    final String jobId = _firestore.collection('jobs').doc().id;
    final newJob = Job(
      id: jobId,
      title: title,
      description: description,
      value: value,
      createdByUserId: createdByUserId,
      accepted: false,
      declined: false,
      acceptedByUserId: null,
    );

    await _firestore.collection('jobs').doc(jobId).set(newJob.toFirestore());
  }

  /// Exclui uma vaga do Firestore e suas candidaturas associadas.
  Future<void> deleteJob(String jobId) async {
    // 1. Deletar todas as candidaturas associadas à vaga
    final applications = await _firestore.collection('jobs').doc(jobId).collection('applications').get();
    for (var doc in applications.docs) {
      final app = Application.fromFirestore(doc);
      // Se a aplicação foi aceita, remover o jobId do jobsCompleted do prestador
      if (app.status == 'accepted') {
        await _firestore.collection('users').doc(app.applicantId).update({
          'jobsCompleted': FieldValue.arrayRemove([jobId]),
        });
      }
      await doc.reference.delete(); // Deleta o documento da aplicação
    }
    // 2. Finalmente, exclui a vaga em si
    await _firestore.collection('jobs').doc(jobId).delete();
  }

  /// Função para o prestador aplicar para uma vaga.
  Future<void> applyForJob(String jobId, String applicantId) async {
    // Verifica se o usuário já se candidatou a esta vaga
    final existingApplication = await _firestore
        .collection('jobs')
        .doc(jobId)
        .collection('applications')
        .where('applicantId', isEqualTo: applicantId)
        .limit(1)
        .get();

    if (existingApplication.docs.isNotEmpty) {
      throw Exception('Você já se candidatou a esta vaga.');
    }

    final newApplication = Application(
      jobId: jobId,
      applicantId: applicantId,
      status: 'pending',
      appliedAt: Timestamp.now(),
    );
    await _firestore.collection('jobs').doc(jobId).collection('applications').add(newApplication.toFirestore());
  }

  /// Aceita uma candidatura e atualiza o status da vaga.
  Future<void> acceptApplication(String jobId, String applicationId, String acceptedByUserId) async {
    // 1. Atualiza o status da aplicação para 'accepted'
    await _firestore.collection('jobs').doc(jobId).collection('applications').doc(applicationId).update({
      'status': 'accepted',
    });

    // 2. Atualiza a vaga para indicar que foi aceita e por quem
    await _firestore.collection('jobs').doc(jobId).update({
      'accepted': true,
      'declined': false, // Garante que declined seja false
      'acceptedByUserId': acceptedByUserId,
    });

    // 3. Adiciona a vaga à lista de trabalhos concluídos do prestador
    await _firestore.collection('users').doc(acceptedByUserId).update({
      'jobsCompleted': FieldValue.arrayUnion([jobId]),
    });

    // 4. Recusa todas as outras candidaturas pendentes para esta vaga
    final otherApplications = await _firestore.collection('jobs').doc(jobId).collection('applications').where('status', isEqualTo: 'pending').get();
    for (var doc in otherApplications.docs) {
      if (doc.id != applicationId) {
        await doc.reference.update({'status': 'declined'});
      }
    }
  }

  /// Recusa uma candidatura.
  Future<void> declineApplication(String jobId, String applicationId, String declinedByUserId) async {
    // 1. Atualiza o status da aplicação para 'declined'
    await _firestore.collection('jobs').doc(jobId).collection('applications').doc(applicationId).update({
      'status': 'declined',
    });

    // 2. Remove o jobId da lista de jobsCompleted do prestador (se estiver lá)
    await _firestore.collection('users').doc(declinedByUserId).update({
      'jobsCompleted': FieldValue.arrayRemove([jobId]),
    });

    // 3. Verifica se a vaga precisa ser "desatribuída" (se não houver mais aplicações aceitas ou pendentes)
    final remainingPendingApplications = await _firestore.collection('jobs').doc(jobId).collection('applications').where('status', isEqualTo: 'pending').get();
    final acceptedApplication = await _firestore.collection('jobs').doc(jobId).collection('applications').where('status', isEqualTo: 'accepted').get();

    // Se não houver mais candidaturas pendentes e nenhuma candidatura aceita,
    // a vaga volta para o estado original (não aceita, não recusada, sem prestador atribuído).
    if (remainingPendingApplications.docs.isEmpty && acceptedApplication.docs.isEmpty) {
      await _firestore.collection('jobs').doc(jobId).update({
        'accepted': false,
        'declined': false,
        'acceptedByUserId': null,
      });
    }
  }
}