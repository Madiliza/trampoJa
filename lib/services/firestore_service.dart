import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  /// Buscar dados do usuário
  Future<DocumentSnapshot> getUser() {
    return _db.collection('users').doc(uid).get();
  }

  /// Salvar/Atualizar dados
  Future<void> saveUser(Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Atualizar foto
  Future<void> updatePhoto(String photoUrl) {
    return _db.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
    });
  }
}
