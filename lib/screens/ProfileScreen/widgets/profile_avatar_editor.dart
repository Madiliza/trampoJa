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
          CircleAvatar(
            radius: 60,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : const NetworkImage('https://via.placeholder.com/150'),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: onEditPressed,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: laranjaVivo,
                child: Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}