import 'package:flutter/material.dart';
import 'package:trampoja_app/screens/LoginScreen.dart';
import 'package:trampoja_app/screens/homepage.dart'; // Certifique-se que homepage está correta
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Este arquivo é gerado automaticamente pelo FlutterFire CLI
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Garanta que usa as opções padrão
  );

  // A verificação do usuário será feita de forma reativa na tela inicial (AuthWrapper)
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: "Trampo Já",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      home: AuthWrapper(), // Usar um AuthWrapper para gerenciar a navegação inicial
    );
  }
}

// Novo Widget para gerenciar o estado de autenticação inicial
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          // Se o usuário está logado, vai para a Homepage
          print('Usuário logado no AuthWrapper: ${snapshot.data!.uid}');
          return const Homepage();
        } else {
          // Se o usuário não está logado, vai para a LoginScreen
          print('Nenhum usuário logado no AuthWrapper.');
          return const LoginScreen();
        }
      },
    );
  }
}