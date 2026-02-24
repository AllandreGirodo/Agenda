import 'package:flutter/material.dart';
import 'view/login_view.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // Será gerado pelo flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicialização do Firebase (descomente após configurar o projeto no console)
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Massoterapia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginView(),
    );
  }
}
