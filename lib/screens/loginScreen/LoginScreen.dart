import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Certifique-se de que este caminho está correto para o seu AuthService atualizado
import '../registerScreen/RegisterScreen.dart';
// Não precisamos importar homepage aqui, pois o AuthWrapper lida com isso.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Instância do seu AuthService

  bool _isLoading = false;
  String? _error; // Para exibir mensagens de erro ao usuário

  Future<void> _login() async {
    // Define o estado de carregamento e limpa erros anteriores
    // É seguro chamar setState aqui porque o widget certamente está montado no início de _login()
    if (!mounted) return; // Primeira verificação: garante que o widget ainda está ativo
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    print('LoginScreen: Tentando login com E-mail: $email, Senha: $password');

    final result = await _authService.login(email, password);

    // IMPORTANTE: Verifique se o widget ainda está montado ANTES de chamar setState após uma operação assíncrona.
    if (!mounted) return;

    // Finaliza o estado de carregamento
    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      print('LoginScreen: Login bem-sucedido! O AuthWrapper no main.dart vai lidar com a navegação.');
      // A navegação agora é gerenciada pelo AuthWrapper.
      // A LoginScreen será descartada assim que o AuthWrapper reconstruir a Homepage.
    } else {
      print('LoginScreen: Erro no login: ${result['error']}');
      // A verificação `!mounted` aqui já garante que o setState só será chamado se a tela ainda estiver visível.
      setState(() {
        _error = result['error'];
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const laranja = Color(0xFFFF6F00);
    const laranjaSuave = Color(0xFFFFA040);
    const pessegoClaro = Color(0xFFFFE0B2);
    const cinzaEscuro = Color(0xFF333333);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: pessegoClaro,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bem-vindo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cinzaEscuro,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Faça login para continuar',
                  style: TextStyle(fontSize: 16, color: cinzaEscuro),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'E-mail',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email, color: laranja),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Senha',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: laranja),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: laranja,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Entrar',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // TODO: Implementar recuperação de senha
                    print('Esqueci minha senha clicado');
                  },
                  child: const Text(
                    'Esqueci minha senha',
                    style: TextStyle(color: laranjaSuave, fontSize: 15),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    'Criar uma conta',
                    style: TextStyle(color: laranjaSuave, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}