import 'package:cloud_firestore/cloud_firestore.dart'; // Importe para usar o Timestamp, se necessário

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
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
    required this.profession,
    required this.experience,
    required this.skills,
    required this.aboutMe,
    required this.photoUrl,
    required this.jobsCompleted,
    required this.jobsNotAttended,
    required this.feedbacks,
  });

  factory UserModel.fromDocument(Map<String, dynamic> doc, String uid) {
    return UserModel(
      uid: uid,
      name: doc['name'] ?? '',
      email: doc['email'] ?? '',
      phone: doc['phone'] ?? '',
      profession: doc['profession'] ?? '',
      experience: doc['experience'] ?? '',
      skills: doc['skills'] ?? '',
      aboutMe: doc['aboutMe'] ?? '',
      photoUrl: doc['photoUrl'] ?? '',
      // Certifique-se de que jobsCompleted e jobsNotAttended são listas de Strings
      jobsCompleted: List<String>.from(doc['jobsCompleted'] ?? []),
      jobsNotAttended: List<String>.from(doc['jobsNotAttended'] ?? []),
      // Certifique-se de que feedbacks são listas de Map<String, dynamic>
      feedbacks: List<Map<String, dynamic>>.from(doc['feedbacks'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
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