import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic> gameData = {};
  User? user;
  double visibilityRange = 100.0;
  String roomCode = '';
  Timer? aiTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    roomCode = ModalRoute.of(context)?.settings.arguments as String;
    user = _auth.currentUser;
    _firestore.collection('games').doc(roomCode).snapshots().listen((snapshot) {
      setState(() {
        gameData = snapshot.data()!;
        checkVisibility();
        autoShoot();
      });
    });

    startAiMovement();
  }

  @override
  void dispose() {
    aiTimer?.cancel();
    super.dispose();
  }

  void movePlayer(int dx, int dy) {
    var playerData = gameData['players'][user!.uid];
    int newX = playerData['position']['x'] + dx;
    int newY = playerData['position']['y'] + dy;

    _firestore.collection('games').doc(roomCode).update({
      'players.${user!.uid}.position': {'x': newX, 'y': newY},
    });
  }

  void startAiMovement() {
    aiTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      gameData['players'].forEach((key, value) {
        if (value['isAI'] == true) {
          moveAIPlayer(key);
        }
      });
    });
  }

  void moveAIPlayer(String aiPlayerId) {
    int dx = Random().nextInt(3) - 1;
    int dy = Random().nextInt(3) - 1;

    var aiPlayerData = gameData['players'][aiPlayerId];
    int newX = aiPlayerData['position']['x'] + dx;
    int newY = aiPlayerData['position']['y'] + dy;

    _firestore.collection('games').doc(roomCode).update({
      'players.$aiPlayerId.position': {'x': newX, 'y': newY},
    });

    checkVisibility();
    autoShoot();
  }

  void checkVisibility() {
    var playerData = gameData['players'][user!.uid];
    double playerX = playerData['position']['x'] * 10.0;
    double playerY = playerData['position']['y'] * 10.0;

    gameData['players'].forEach((key, value) {
      if (key != user!.uid) {
        double enemyX = value['position']['x'] * 10.0;
        double enemyY = value['position']['y'] * 10.0;
        bool inRange = (playerX - enemyX).abs() < visibilityRange && (playerY - enemyY).abs() < visibilityRange;

        _firestore.collection('games').doc(roomCode).update({
          'players.$key.visible': inRange,
        });
      }
    });
  }

  void autoShoot() {
    var playerData = gameData['players'][user!.uid];
    double playerX = playerData['position']['x'] * 10.0;
    double playerY = playerData['position']['y'] * 10.0;

    gameData['players'].forEach((key, value) {
      if (key != user!.uid && value['visible'] == true) {
        double enemyX = value['position']['x'] * 10.0;
        double enemyY = value['position']['y'] * 10.0;
        bool inFront = (playerX - enemyX).abs() < 10.0 && playerY < enemyY;

        if (inFront) {
          shoot(key);
        }
      }
    });
  }

  void shoot(String targetId) {
    int targetHealth = gameData['players'][targetId]['health'];
    targetHealth -= 10;

    if (targetHealth <= 0) {
      // End game or remove player
    } else {
      _firestore.collection('games').doc(roomCode).update({
        'players.$targetId.health': targetHealth,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (gameData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Battle Arena')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Battle Arena')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: gameData['players'].entries.map<Widget>((entry) {
                var player = entry.value;
                bool isCurrentPlayer = entry.key == user!.uid;
                return Positioned(
                  left: player['position']['x'] * 10.0,
                  top: player['position']['y'] * 10.0,
                  child: Visibility(
                    visible: isCurrentPlayer || player['visible'],
                    child: Container(
                      width: 50,
                      height: 50,
                      color: isCurrentPlayer ? Colors.blue : Colors.red,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: Icon(Icons.arrow_upward), onPressed: () => movePlayer(0, -1)),
              IconButton(icon: Icon(Icons.arrow_downward), onPressed: () => movePlayer(0, 1)),
              IconButton(icon: Icon(Icons.arrow_back), onPressed: () => movePlayer(-1, 0)),
              IconButton(icon: Icon(Icons.arrow_forward), onPressed: () => movePlayer(1, 0)),
            ],
          ),
        ],
      ),
    );
  }
}
