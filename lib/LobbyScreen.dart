import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LobbyScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateRoomCode() {
    var rng = Random();
    return (rng.nextInt(9000) + 1000).toString();  // Generates a 4-digit code
  }

  Future<void> createRoom(BuildContext context, {bool withComputer = false}) async {
    String roomCode = generateRoomCode();
    User? user = _auth.currentUser;

    Map<String, dynamic> players = {
      user!.uid: {'position': {'x': 0, 'y': 0}, 'health': 100, 'visible': false},
    };

    if (withComputer) {
      for (int i = 1; i <= 3; i++) {
        players['computer_$i'] = {
          'position': {'x': Random().nextInt(10), 'y': Random().nextInt(10)},
          'health': 100,
          'visible': false,
          'isAI': true,
        };
      }
    }

    await _firestore.collection('games').doc(roomCode).set({
      'players': players,
      'status': 'waiting',
    });

    Navigator.pushReplacementNamed(context, '/game', arguments: roomCode);
  }

  Future<void> joinRoom(String roomCode, BuildContext context) async {
    User? user = _auth.currentUser;
    DocumentReference gameRef = _firestore.collection('games').doc(roomCode);

    await gameRef.update({
      'players.${user!.uid}': {'position': {'x': 5, 'y': 5}, 'health': 100, 'visible': false},
      'status': 'active'
    });

    Navigator.pushReplacementNamed(context, '/game', arguments: roomCode);
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController roomCodeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/sign_in');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => createRoom(context),
              child: Text('Create Room'),
            ),
            ElevatedButton(
              onPressed: () => createRoom(context, withComputer: true),
              child: Text('Play with Computer'),
            ),
            TextField(
              controller: roomCodeController,
              decoration: InputDecoration(labelText: 'Enter Room Code'),
            ),
            ElevatedButton(
              onPressed: () => joinRoom(roomCodeController.text, context),
              child: Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}
