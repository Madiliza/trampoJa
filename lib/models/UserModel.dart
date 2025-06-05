// user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String userType; // Novo campo para o tipo de usuário
  final String profession;
  final String experience;
  final String skills;
  final String aboutMe;
  final String photoUrl;
  final List<String> jobsCompleted;
  final List<String> jobsNotAttended;
  final List<Map<String, dynamic>> feedbacks;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType, // Adicionar ao construtor
    this.profession = '', // Adicionado default para evitar null se não for prestador
    this.experience = '', // Adicionado default
    this.skills = '', // Adicionado default
    this.aboutMe = '', // Adicionado default
    this.photoUrl = '',
    this.jobsCompleted = const [],
    this.jobsNotAttended = const [],
    this.feedbacks = const [],
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    // É crucial garantir que data seja Map<String, dynamic> e não null.
    // O '.data()' pode retornar null se o documento não existir,
    // mas o 'snapshot.data!.exists' no widget já deveria pegar isso.
    // Mesmo assim, um cast seguro é bom.
    final data = doc.data() as Map<String, dynamic>?;

    // Se por alguma razão data for null aqui (o que não deveria acontecer com a verificação anterior),
    // ou para documentos vazios, podemos lançar um erro ou retornar um modelo padrão.
    if (data == null) {
      throw StateError('Missing data for UserModel from document ${doc.id}');
    }

    return UserModel(
      uid: doc.id, // uid vem do doc.id agora
      name: data['name'] as String? ?? '', // Explicitamente cast como String? para segurança
      email: data['email'] as String? ?? '',
      phone: data['telefone'] as String? ?? '',
      userType: data['userType'] as String? ?? 'prestador', // Define um valor padrão, ou trate a lógica de cadastro
      profession: data['profissão'] as String? ?? '',
      experience: data['experiencias'] as String? ?? '',
      skills: data['habilidades'] as String? ?? '',
      aboutMe: data['sobre mim'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      // Tratamento mais robusto para listas
      jobsCompleted: (data['trabalhos completos'] is Iterable) ? List<String>.from(data['trabalhos completos']) : [],
      jobsNotAttended: (data['trabalhos não atendidos'] is Iterable) ? List<String>.from(data['trabalhos não atendidos']) : [],
      feedbacks: (data['feedbacks'] is Iterable) ? List<Map<String, dynamic>>.from(data['feedbacks']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'telefone': phone,
      'userType': userType, // Adicionar ao toMap
      'profissão': profession,
      'experiencia': experience,
      'habilidades': skills,
      'sobre mim': aboutMe,
      'photoUrl': photoUrl,
      'Trabalhos completos': jobsCompleted,
      'empregos não atendidos': jobsNotAttended,
      'feedbacks': feedbacks,
    };
  }
}