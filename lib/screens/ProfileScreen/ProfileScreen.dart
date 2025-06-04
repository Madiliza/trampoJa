import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Foto de perfil
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(
                    'https://via.placeholder.com/150', // URL da foto
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      // Função para alterar foto
                    },
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFFF6F00),
                      child: Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Seu Nome Aqui',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          const Text(
            'Profissão ou título',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Seções do Perfil
          _buildSection(
            context,
            title: 'Dados Pessoais e Segurança',
            icon: Icons.person,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Email', 'email@email.com'),
                _infoRow('Telefone', '(11) 91234-5678'),
                _infoRow('Senha', '********'),
                const SizedBox(height: 8),
                _editButton(() {
                  // Ação para editar dados pessoais
                }),
              ],
            ),
          ),

          _buildSection(
            context,
            title: 'Informações Profissionais',
            icon: Icons.work,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Profissão', 'Designer Gráfico'),
                _infoRow('Experiência', '5 anos'),
                _infoRow('Habilidades', 'Photoshop, Figma, Illustrator'),
                const SizedBox(height: 8),
                _editButton(() {
                  // Editar informações profissionais
                }),
              ],
            ),
          ),

          _buildSection(
            context,
            title: 'Sobre Mim',
            icon: Icons.info,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sou um profissional apaixonado por design...',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                _editButton(() {
                  // Editar Sobre Mim
                }),
              ],
            ),
          ),

          _buildSection(
            context,
            title: 'Jobs Realizados',
            icon: Icons.check_circle,
            content: Column(
              children: [
                _jobItem('Design de Logo - Cliente X'),
                _jobItem('Site Institucional - Cliente Y'),
                _jobItem('Banner para Redes - Cliente Z'),
                const SizedBox(height: 8),
              ],
            ),
          ),

          _buildSection(
            context,
            title: 'Jobs Não Compareceu',
            icon: Icons.cancel,
            content: Column(
              children: [
                _jobItem('Criação de Cartão - Cliente A'),
                const SizedBox(height: 8),
              ],
            ),
          ),

          _buildSection(
            context,
            title: 'Feedbacks',
            icon: Icons.reviews,
            content: Column(
              children: [
                _feedbackItem('Cliente X', 'Ótimo trabalho, recomendo!', 5),
                _feedbackItem('Cliente Y', 'Muito profissional.', 4),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title,
        required IconData icon,
        required Widget content}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xFFFF6F00)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [content],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editButton(VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.edit, size: 18, color: Color(0xFFFF6F00)),
        label: const Text(
          'Editar',
          style: TextStyle(color: Color(0xFFFF6F00)),
        ),
      ),
    );
  }

  Widget _jobItem(String job) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.work, color: Colors.grey),
      title: Text(job),
    );
  }

  Widget _feedbackItem(String client, String feedback, int rating) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person, color: Colors.grey),
      title: Text(client),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(feedback),
          Row(
            children: List.generate(
              5,
                  (index) => Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ),
        ],
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