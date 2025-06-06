import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  // Flag para controlar o estado do ImagePicker, evitando múltiplas aberturas.
  bool _isPickingImage = false;

  /// Atualiza os dados do usuário no Firestore para um dado ID de usuário.
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  /// Seleciona uma imagem da galeria e a envia para o Firebase Storage.
  /// Em seguida, atualiza o perfil do usuário no Firestore com a nova URL da imagem.
  Future<String?> pickAndUploadProfileImage(String userId, BuildContext context) async {
    // Impede que o seletor de imagem seja aberto múltiplas vezes.
    if (_isPickingImage) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O seletor de imagem já está aberto. Por favor, aguarde ou feche-o.')),
        );
      }
      return null;
    }

    _isPickingImage = true; // Define a flag como true antes de iniciar a operação.

    try {
      // 1. Obtém o usuário autenticado do Firebase.
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      // Se nenhum usuário Firebase estiver logado, não podemos prosseguir.
      if (firebaseUser == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Usuário não autenticado. Por favor, faça login novamente.')),
          );
        }
        return null;
      }

      // --- Início da lógica de seleção e upload de imagem ---
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      // Se nenhuma imagem foi selecionada (usuário cancelou).
      if (image == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma imagem selecionada.')),
          );
        }
        return null;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carregando imagem...')),
        );
      }

      // Define o caminho no Firebase Storage (ex: 'profile_pictures/userId/timestamp.jpg').
      final String filePath = 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File file = File(image.path);

      // 2. Cria uma referência para o local de upload no Firebase Storage.
      final Reference ref = _firebaseStorage.ref().child(filePath);

      // 3. Envia o arquivo para o Firebase Storage.
      final UploadTask uploadTask = ref.putFile(file);

      // 4. Aguarda a conclusão do upload e obtém o snapshot.
      final TaskSnapshot snapshot = await uploadTask;

      // 5. Obtém a URL de download da imagem enviada.
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 6. Atualiza a URL da foto no Firestore.
      if (context.mounted) {
        await updateUserData(userId, {'photoUrl': downloadUrl});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')),
        );
      }
      return downloadUrl;

    } on FirebaseException catch (e) {
      print('Erro no Firebase Storage: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no upload da imagem: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      print('Erro inesperado ao selecionar/enviar imagem: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar a foto de perfil: $e')),
        );
      }
      return null;
    } finally {
      // Garante que a flag seja resetada, independente de sucesso ou erro.
      _isPickingImage = false;
    }
  }
}