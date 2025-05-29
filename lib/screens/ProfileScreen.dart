import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AboutMePage(),
    OptionsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: _TopButton(
                label: 'Sobre Mim',
                isSelected: _selectedIndex == 0,
                onTap: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
            ),
            Expanded(
              child: _TopButton(
                label: 'Opções',
                isSelected: _selectedIndex == 1,
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            color: const Color(0xFFFF6F00), // Linha delicada abaixo
            height: 2,
          ),
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class _TopButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _TopButton({
    required this.label,
    required this.onTap,
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        height: kToolbarHeight,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFFF6F00) // Cor laranja quando selecionado
                : const Color(0xFF333333), // Cor padrão quando não selecionado
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Página Sobre Mim
class AboutMePage extends StatelessWidget {
  const AboutMePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Conteúdo Sobre Mim',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

// Página Opções
class OptionsPage extends StatelessWidget {
  const OptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Conteúdo de Opções',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
