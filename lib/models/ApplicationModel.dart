// models/ApplicationModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  String? id; // O ID único do documento da aplicação
  String jobId; // ID da vaga para a qual a candidatura foi feita
  String applicantId; // ID do prestador que se candidatou
  String status; // 'pending', 'accepted', 'declined'
  Timestamp appliedAt; // Data e hora da candidatura

  Application({
    this.id,
    required this.jobId,
    required this.applicantId,
    this.status = 'pending', // Padrão: pendente
    required this.appliedAt,
  });

  factory Application.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Application(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      applicantId: data['applicantId'] ?? '',
      status: data['status'] ?? 'pending',
      appliedAt: data['appliedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'applicantId': applicantId,
      'status': status,
      'appliedAt': appliedAt,
    };
  }
}