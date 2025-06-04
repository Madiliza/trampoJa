import 'package:firebase_auth/firebase_auth.dart'; // Importe o pacote de autenticação
import 'package:cloud_firestore/cloud_firestore.dart'; // Importe o pacote do Firestore
import '../models/UserModel.dart'; // Seu modelo de usuário

class AuthService {
  // Não precisamos mais da API Key e Project ID aqui para operações do SDK
  // final String apiKey = 'AIzaSyAfOdibv5xLcfr0L5Rgb34uH9KinkIITwE';
  // final String projectId = 'trampoja-ff176';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔐 Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Se o login for bem-sucedido, o SDK já atualizou o estado interno.
      // Agora podemos buscar os dados do Firestore usando o SDK do Firestore.
      final User? user = userCredential.user;
      if (user != null) {
        print('AuthService: Login bem-sucedido para UID: ${user.uid}');
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

        if (docSnapshot.exists) {
          final userData = UserModel.fromDocument(docSnapshot.data()!, user.uid);
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
      String userType, // userType não está sendo usado no UserModel, mas mantido aqui
      ) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        print('AuthService: Registro bem-sucedido para UID: ${user.uid}');

        // Criar o modelo de usuário inicial
        final newUserModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          phone: '',
          profession: '',
          experience: '',
          skills: '',
          aboutMe: '',
          photoUrl: '',
          jobsCompleted: [],
          jobsNotAttended: [],
          feedbacks: [],
        );

        // Salvar os dados do usuário no Firestore usando o SDK do Firestore
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

  // O método saveUserData não é mais necessário como uma função separada para HTTP.
  // Ele será chamado diretamente dentro de register() e updateProfile() usando o SDK.
  // Se você ainda precisar de uma função para atualizar dados do usuário, ela usaria o SDK do Firestore.
  Future<void> updateUserDataInFirestore(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      print('AuthService: Dados do usuário atualizados no Firestore para UID: $uid');
    } catch (e) {
      print('AuthService: Erro ao atualizar dados do usuário no Firestore: $e');
      rethrow; // Re-lança o erro para ser tratado na UI
    }
  }

  // O método getUserData não é mais necessário como uma função separada para HTTP.
  // Ele será chamado diretamente na ProfileScreen usando o SDK do Firestore.

  // Método para fazer logout (usando o SDK)
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    print('AuthService: Usuário deslogado.');
  }

  // Stream para observar mudanças no estado de autenticação (melhor prática)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Obter o usuário atual (use com cautela, prefira stream)
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}