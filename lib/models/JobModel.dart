// JobModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para representar uma vaga de emprego.
class Job {
  String? id; // ID do documento Firestore (opcional, será preenchido pelo Firestore)
  String title; // Título da vaga
  String description; // Descrição detalhada da vaga
  double? value; // Novo campo para o valor da vaga, opcional
  bool accepted; // Indica se a vaga foi aceita pelo usuário
  bool declined; // Indica se a vaga foi recusada pelo usuário
  String? createdByUserId; // ID do usuário que criou a vaga
  String? acceptedByUserId; // ID do usuário que aceitou a vaga

  Job({
    this.id,
    required this.title,
    required this.description,
    this.value,
    this.accepted = false,
    this.declined = false,
    this.createdByUserId, // Adicionar ao construtor
    this.acceptedByUserId, // Adicionar ao construtor
  });

  /// Construtor de fábrica para criar um objeto Job a partir de um documento Firestore.
  factory Job.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      value: (data['value'] as num?)?.toDouble(),
      accepted: data['accepted'] ?? false,
      declined: data['declined'] ?? false,
      createdByUserId: data['createdByUserId'], // Obter do Firestore
      acceptedByUserId: data['acceptedByUserId'], // Obter do Firestore
    );
  }

  /// Converte o objeto Job em um mapa para salvar no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'value': value,
      'accepted': accepted,
      'declined': declined,
      'createdByUserId': createdByUserId, // Salvar no Firestore
      'acceptedByUserId': acceptedByUserId, // Salvar no Firestore
    };
  }
}