import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart'; // Importe o Firebase Auth aqui

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<String?> pickAndUploadProfileImage(String userId, BuildContext context) async {
    try {
      // 1. Obter o usuário Firebase autenticado
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      // Se não houver usuário Firebase logado, não podemos prosseguir
      if (firebaseUser == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Usuário não autenticado. Por favor, faça login novamente.')),
          );
        }
        return null;
      }

      // 2. Obter o token JWT do Firebase
      // Isso é necessário para que o Supabase possa autenticar a requisição
      final String? firebaseIdToken = await firebaseUser.getIdToken();

      if (firebaseIdToken == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Não foi possível obter o token de autenticação do Firebase.')),
          );
        }
        return null;
      }

      // 3. Informar ao cliente Supabase sobre o token JWT do Firebase
      // Isso permite que as políticas de RLS do Supabase usem auth.uid() e auth.role() corretamente
      await supabase.auth.setSession(firebaseIdToken); // Configura a sessão Supabase com o token Firebase

      // --- Início da lógica de seleção e upload da imagem ---
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

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

      // Nome do arquivo com subpastas baseadas no userId e timestamp para unicidade
      final String fileName = 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Nome do bucket Supabase, que agora deve ser 'trampojaapp'
      const String bucketName = 'trampojaapp';

      // 4. Realizar o upload da imagem para o Supabase Storage
      // O Supabase usará a sessão configurada com o token Firebase para a checagem de RLS
      final String path = await supabase.storage
          .from(bucketName)
          .upload(
            fileName,
            File(image.path),
            fileOptions: const FileOptions(
              cacheControl: '3600', // Define o cache da imagem
              upsert: true,        // Sobrescreve se o arquivo já existir com o mesmo nome
              contentType: 'image/jpeg', // Tipo de conteúdo para a imagem
            ),
          );

      // 5. Obter a URL pública da imagem recém-carregada
      final String downloadUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      // 6. Atualizar a URL da foto no Firestore
      if (context.mounted) {
        await updateUserData(userId, {'photoUrl': downloadUrl});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')),
        );
      }
      return downloadUrl;

    // Tratamento de exceções específicas do Storage (Supabase)
    } on StorageException catch (e) {
      print('Erro no upload para Supabase Storage: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no upload da imagem: ${e.message}')),
        );
      }
      return null;
    // Tratamento de outras exceções (Firebase, ImagePicker, etc.)
    } catch (e) {
      print('Erro inesperado ao selecionar/enviar imagem: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar a foto de perfil: $e')),
        );
      }
      return null;
    }
  }
}