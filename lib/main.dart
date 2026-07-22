// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text("AI Business Assistant"),
//         ),
//         body: Center(
//           child: Text(
//             "We are alive 😭",
//             style: TextStyle(fontSize: 24),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'providers/notification_provider.dart';
import 'widgets/connectivity_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => NotificationProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "AI Business Assistant",
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFFFF1E8),
          primaryColor: const Color(0xFF2F5DA8),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFF1E8),
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF0D1B3E)),
            titleTextStyle: TextStyle(
              color: Color(0xFF0D1B3E),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}