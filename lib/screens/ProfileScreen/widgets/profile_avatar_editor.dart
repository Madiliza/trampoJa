import 'package:flutter/material.dart';
import 'package:trampoja_app/utils/app_colors.dart';

class ProfileAvatarEditor extends StatelessWidget {
  final String photoUrl;
  final VoidCallback onEditPressed;

  const ProfileAvatarEditor({
    super.key,
    required this.photoUrl,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: branco, // Fundo branco para a borda
              border: Border.all(color: borderColor, width: 3), // Borda sutil
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 65, // Raio um pouco maior
              backgroundColor: Colors.grey[200], // Cor de fundo para placeholder
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null, // Pode ser null para fallback abaixo
              child: photoUrl.isEmpty
                  ? Icon(Icons.person, size: 80, color: Colors.grey[400]) // Ícone placeholder
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector( // Usar GestureDetector para mais controle, se necessário
              onTap: onEditPressed,
              child: Container(
                padding: const EdgeInsets.all(8), // Padding para o ícone
                decoration: BoxDecoration(
                  color: primaryColor, // Sua cor primária
                  shape: BoxShape.circle,
                  border: Border.all(color: branco, width: 3), // Borda branca em volta
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20), // Ícone de câmera
              ),
            ),
          ),
        ],
      ),
    );
  }
}