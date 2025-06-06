// main.dart
import 'package:firebase_auth/firebase_auth.dart' as FBAuth;
import 'package:flutter/material.dart';
import 'package:trampoja_app/screens/loginScreen/LoginScreen.dart';
import 'package:trampoja_app/screens/Homepage/Homepage.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Inicialização do Firebase ---
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(const App());
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FBAuth.User?>(
      stream: FBAuth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          print('Usuário logado no AuthWrapper: ${snapshot.data!.uid}');
          return const Homepage();
        } else {
          print('Nenhum usuário logado no AuthWrapper.');
          return const LoginScreen();
        }
      },
    );
  }
}