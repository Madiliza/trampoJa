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

      await doc.reference.delete(); // Deleta o documento da aplicação
    }
    // 2. Finalmente, exclui a vaga em si
    await _firestore.collection('jobs').doc(jobId).delete();
  }

  /// Função para o prestador aplicar para uma vaga.
  Future<void> applyForJob(String jobId, String applicantId) async {
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

    // 2. Atualiza a vaga para indicar que foi recusada
    await _firestore.collection('jobs').doc(jobId).update({
      'accepted': false, // Garante que accepted seja false
      'declined': true,
      'acceptedByUserId': null, // Limpa o usuário que aceitou
    });

    // 3. Verifica se a vaga precisa ser "desatribuída" (se não houver mais aplicações aceitas ou pendentes)
    final remainingPendingApplications = await _firestore.collection('jobs').doc(jobId).collection('applications').where('status', isEqualTo: 'pending').get();
    final acceptedApplication = await _firestore.collection('jobs').doc(jobId).collection('applications').where('status', isEqualTo: 'accepted').get();

    if (remainingPendingApplications.docs.isEmpty && acceptedApplication.docs.isEmpty) {
      await _firestore.collection('jobs').doc(jobId).update({
        'accepted': false,
        'declined': false,
        'acceptedByUserId': null,
      });
    }
  }
}