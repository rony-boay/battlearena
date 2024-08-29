import 'package:battlearena/GameScreen.dart';
import 'package:battlearena/LobbyScreen.dart';
import 'package:battlearena/SignInScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(BattleArenaApp());
}

class BattleArenaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle Arena',
      initialRoute: '/sign_in',
      routes: {
        '/sign_in': (context) => SignInScreen(),
        '/lobby': (context) => LobbyScreen(),
        '/game': (context) => GameScreen(),
      },
    );
  }
}
