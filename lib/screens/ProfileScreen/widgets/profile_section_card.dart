import 'package:flutter/material.dart';
import 'package:trampoja_app/utils/app_colors.dart';

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget content;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Cantos mais arredondados
      ),
      elevation: 4, // Sombra um pouco mais pronunciada, mas suave
      shadowColor: Colors.black.withOpacity(0.1), // Cor da sombra mais sutil
      child: Padding(
        padding: const EdgeInsets.all(20), // Mais padding interno
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 28), // Ícone maior e cor primária
                const SizedBox(width: 12), // Mais espaço
                Expanded( // Garante que o texto não exceda o limite
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20, // Título maior
                      fontWeight: FontWeight.bold,
                      color: textColorPrimary, // Cor de texto principal
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28, thickness: 1, color: borderColor), // Separador sutil
            content,
          ],
        ),
      ),
    );
  }
}