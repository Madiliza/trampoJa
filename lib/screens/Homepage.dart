import 'package:flutter/material.dart';
import 'package:trampoja_app/Screens/CalendarScreen.dart';
import 'package:trampoja_app/Screens/NotificationScreen.dart';
import 'package:trampoja_app/screens/ProfileScreen/ProfileScreen.dart'; // Corrija o caminho se necessário
import 'package:trampoja_app/Screens/JobScreen.dart';
import 'package:trampoja_app/screens/MessagesScreen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 2; // Índice inicial para a tela de Vagas (JobScreen)

  final List<Widget> _screens = const [
    CalendarScreen(),
    NotificationScreen(),
    JobScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6F00),
        onPressed: () {
          _onItemTapped(2); // Vai para "Vagas"
        },
        child: const Icon(Icons.work_outline, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.calendar_month, 0, 'Calendário'),
              _buildNavItem(Icons.notifications_outlined, 1, 'Notificações'),
              const SizedBox(width: 40), // Espaço para o botão central
              _buildNavItem(Icons.chat_outlined, 3, 'Mensagens'),
              _buildNavItem(Icons.person_outline, 4, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFF6F00) : Colors.grey,
          ),
          if (isSelected)
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFF6F00),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}