// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/UserModel.dart'; // Seu modelo de usuário

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔐 Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        print('AuthService: Login bem-sucedido para UID: ${user.uid}');
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

        if (docSnapshot.exists) {
          // Passamos o doc.id (user.uid) explicitamente para o fromDocument
          final userData = UserModel.fromDocument(docSnapshot);
          return {
            'success': true,
            'user': userData, // Retorna o UserModel completo
          };
        } else {
          // Se o documento do usuário não existe no Firestore após o login
          print('AuthService: Documento do usuário não encontrado no Firestore para UID: ${user.uid}');
          return {
            'success': false,
            'error': 'Dados do perfil não encontrados. Por favor, complete seu cadastro.',
          };
        }
      } else {
        return {'success': false, 'error': 'Usuário não retornado após o login.'};
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Nenhum usuário encontrado para esse e-mail.';
          break;
        case 'wrong-password':
          errorMessage = 'Senha incorreta.';
          break;
        case 'invalid-email':
          errorMessage = 'O formato do e-mail é inválido.';
          break;
        case 'user-disabled':
          errorMessage = 'Este usuário foi desativado.';
          break;
        default:
          errorMessage = 'Erro de login: ${e.message ?? "Ocorreu um erro desconhecido."}';
      }
      print('AuthService: Erro de login - ${e.code}: $errorMessage');
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('AuthService: Erro inesperado durante o login: $e');
      return {'success': false, 'error': 'Ocorreu um erro inesperado.'};
    }
  }

  /// 📝 Cadastro
  Future<Map<String, dynamic>> register(
      String email,
      String password,
      String name,
      String userType, // userType agora é usado
      ) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        print('AuthService: Registro bem-sucedido para UID: ${user.uid}');

        // Criar o modelo de usuário inicial, passando o userType recebido
        final newUserModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          phone: '',
          userType: userType, // 🔥 AQUI: userType está sendo passado corretamente
          profession: '',
          experience: '',
          skills: '',
          aboutMe: '',
          photoUrl: '',
          jobsCompleted: const [], // Usar const []
          jobsNotAttended: const [], // Usar const []
          feedbacks: const [], // Usar const []
        );

        // Salvar os dados do usuário no Firestore
        await _firestore.collection('users').doc(user.uid).set(newUserModel.toMap());

        print('AuthService: Dados do usuário salvos no Firestore para UID: ${user.uid}');
        return {
          'success': true,
          'user': newUserModel, // Retorna o UserModel completo
        };
      } else {
        return {'success': false, 'error': 'Usuário não retornado após o registro.'};
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'A senha fornecida é muito fraca.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Uma conta para esse e-mail já existe.';
          break;
        case 'invalid-email':
          errorMessage = 'O formato do e-mail é inválido.';
          break;
        default:
          errorMessage = 'Erro de registro: ${e.message ?? "Ocorreu um erro desconhecido."}';
      }
      print('AuthService: Erro de registro - ${e.code}: $errorMessage');
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('AuthService: Erro inesperado durante o registro: $e');
      return {'success': false, 'error': 'Ocorreu um erro inesperado.'};
    }
  }

  // Método para atualizar dados do usuário no Firestore
  Future<void> updateUserDataInFirestore(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      print('AuthService: Dados do usuário atualizados no Firestore para UID: $uid');
    } catch (e) {
      print('AuthService: Erro ao atualizar dados do usuário no Firestore: $e');
      rethrow; // Re-lança o erro para ser tratado na UI
    }
  }

  // Método para fazer logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    print('AuthService: Usuário deslogado.');
  }

  // Stream para observar mudanças no estado de autenticação
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Obter o usuário atual
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}