import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para representar uma vaga de emprego na plataforma.
class Job {
  String? id; // O ID único do documento no Firestore. Pode ser nulo antes de salvar.
  String title; // O título da vaga.
  String description; // A descrição detalhada do trabalho a ser realizado.
  double? value; // O valor monetário oferecido pela vaga (opcional).

  // Campos de status e relacionamento da vaga:
  bool accepted; // Indica se a vaga foi aceita por um prestador de serviço.
  bool declined; // Indica se a vaga foi recusada (pelo contratante).
  String? createdByUserId; // O ID do usuário (contratante) que criou esta vaga.
  String? acceptedByUserId; // O ID do usuário (prestador) que aceitou a vaga (quando accepted é true).

  /// Construtor principal para criar uma instância de Job.
  Job({
    this.id,
    required this.title,
    required this.description,
    this.value,
    this.accepted = false, // Padrão: vaga não aceita.
    this.declined = false, // Padrão: vaga não recusada.
    this.createdByUserId,
    this.acceptedByUserId,
  });

  /// Construtor de fábrica para criar um objeto [Job] a partir de um [DocumentSnapshot] do Firestore.
  /// Isso é usado ao ler dados do banco de dados.
  factory Job.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      value: (data['value'] as num?)?.toDouble(),
      accepted: data['accepted'] ?? false,
      declined: data['declined'] ?? false,
      createdByUserId: data['createdByUserId'],
      acceptedByUserId: data['acceptedByUserId'],
    );
  }

  /// Converte o objeto [Job] em um mapa de chave-valor para ser salvo no Firestore.
  /// Isso é usado ao escrever dados no banco de dados.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'value': value,
      'accepted': accepted,
      'declined': declined,
      'createdByUserId': createdByUserId,
      'acceptedByUserId': acceptedByUserId,
    };
  }
}