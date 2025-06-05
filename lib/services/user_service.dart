import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Para SnackBar e BuildContext, se o serviço precisar
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<String?> pickAndUploadProfileImage(String userId, BuildContext context) async {
    try {
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

      final String fileName = 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      const String bucketName = 'imagens-do-app';

      final String path = await supabase.storage
          .from(bucketName)
          .upload(
            fileName,
            File(image.path),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final String downloadUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      if (context.mounted) {
        await updateUserData(userId, {'photoUrl': downloadUrl});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')),
        );
      }
      return downloadUrl;
    } on StorageException catch (e) {
      print('Erro no upload para Supabase Storage: ${e.message}');
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
    }
  }
}