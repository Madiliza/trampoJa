import 'package:flutter/material.dart';
import 'package:trampoja_app/utils/app_colors.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8), // Mais espaçamento vertical
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha ao topo
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:', // Adiciona dois pontos para clareza
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textColorPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: textColorSecondary,
              ),
              overflow: TextOverflow.ellipsis, // Trunca textos longos
              maxLines: 2, // Permite 2 linhas antes de truncar
            ),
          ),
        ],
      ),
    );
  }
}