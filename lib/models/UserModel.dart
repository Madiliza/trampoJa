// user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String userType;
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
    required this.userType,
    this.profession = '',
    this.experience = '',
    this.skills = '',
    this.aboutMe = '',
    this.photoUrl = '',
    this.jobsCompleted = const [],
    this.jobsNotAttended = const [],
    this.feedbacks = const [],
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError('Missing data for UserModel from document ${doc.id}');
    }

    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '', // Chave padronizada (se você renomear no Firestore)
      userType: data['userType'] as String? ?? 'prestador',
      profession: data['profession'] as String? ?? '', // Chave padronizada
      experience: data['experience'] as String? ?? '', // Chave padronizada
      skills: data['skills'] as String? ?? '',       // Chave padronizada
      aboutMe: data['aboutMe'] as String? ?? '',     // Chave padronizada
      photoUrl: data['photoUrl'] as String? ?? '',
      jobsCompleted: (data['jobsCompleted'] is Iterable) ? List<String>.from(data['jobsCompleted']) : [], // Chave padronizada
      jobsNotAttended: (data['jobsNotAttended'] is Iterable) ? List<String>.from(data['jobsNotAttended']) : [], // Chave padronizada
      feedbacks: (data['feedbacks'] is Iterable) ? List<Map<String, dynamic>>.from(data['feedbacks']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone, // Chave padronizada
      'userType': userType,
      'profession': profession, // Chave padronizada
      'experience': experience, // Chave padronizada
      'skills': skills,         // Chave padronizada
      'aboutMe': aboutMe,       // Chave padronizada
      'photoUrl': photoUrl,
      'jobsCompleted': jobsCompleted, // Chave padronizada
      'jobsNotAttended': jobsNotAttended, // Chave padronizada
      'feedbacks': feedbacks,
    };
  }
}