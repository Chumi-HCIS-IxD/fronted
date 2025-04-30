// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'pages/login_page.dart';
// import 'pages/home_page.dart';
// import 'firebase_options.dart'; // flutterfire configure
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   final prefs = await SharedPreferences.getInstance();
//   final token = prefs.getString('userToken');
//   runApp(MyApp(isLoggedIn: token != null));
// }
//
// class MyApp extends StatelessWidget {
//   final bool isLoggedIn;
//   const MyApp({Key? key, this.isLoggedIn = true}) : super(key: key);
// // class MyApp extends StatelessWidget {
// //   final bool isLoggedIn;
// //
// //   const MyApp({super.key, required this.isLoggedIn});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: '教學平台',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: const Color(0xFFF9F9F9),
//       ),
//       home: isLoggedIn ? const HomePage() : const LoginPage(),
//     );
//   }
// }


// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'MCQ_Game/room_selection_page.dart';
import 'MCQ_Game/room_page.dart';
import 'MCQ_Game/unit_selection_page.dart';
import 'MCQ_Game/mcq_game_page.dart';
import 'MCQ_Game/result_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('userToken');
  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '教學平台',
      debugShowCheckedModeBanner: false,
      // 一律使用 routes + initialRoute
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (ctx)   => const LoginPage(),
        '/register': (ctx)=> const RegisterPage(),
        '/home': (ctx)    => const HomePage(),
        '/roomSelection': (ctx) => const RoomSelectionPage(isTeacher: false),
        '/room': (ctx)    => const RoomPage(),
        '/unitSelection': (ctx) => const UnitSelectionPage(),
        '/mcqGame': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments
          as Map<String, String>;
          return McqGamePage(
            unitId: args['unit']!,
            roomId: args['room']!,
          );
        },
        '/result': (ctx)  => const ResultPage(),
      },
    );
  }
}