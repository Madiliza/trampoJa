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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id, // uid vem do doc.id agora
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      userType: data['userType'] ?? 'prestador', // Define um valor padrão, ou trate a lógica de cadastro
      profession: data['profession'] ?? '',
      experience: data['experience'] ?? '',
      skills: data['skills'] ?? '',
      aboutMe: data['aboutMe'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      jobsCompleted: List<String>.from(data['jobsCompleted'] ?? []),
      jobsNotAttended: List<String>.from(data['jobsNotAttended'] ?? []),
      feedbacks: List<Map<String, dynamic>>.from(data['feedbacks'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType, // Adicionar ao toMap
      'profession': profession,
      'experience': experience,
      'skills': skills,
      'aboutMe': aboutMe,
      'photoUrl': photoUrl,
      'jobsCompleted': jobsCompleted,
      'jobsNotAttended': jobsNotAttended,
      'feedbacks': feedbacks,
    };
  }
}