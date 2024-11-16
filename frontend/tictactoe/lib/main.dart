import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe 4x4',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LevelSelectionScreen(),
    );
  }
}

class LevelSelectionScreen extends StatelessWidget {
  final List<String> levels = ["Random", "Minimax Easy", "Minimax Medium", "Minimax Hard", "Expectimax"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tic Tac Toe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Select Difficulty Level',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.blueGrey[800]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              // Buttons for difficulty levels
              for (var level in levels) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TicTacToeScreen(level: level),
                        ),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class TicTacToeScreen extends StatefulWidget {
  final String level;
  TicTacToeScreen({required this.level});

  @override
  _TicTacToeScreenState createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<List<String>> board = List.generate(4, (_) => List.generate(4, (_) => ''));
  List<List<Color>> colors = List.generate(4, (_) => List.generate(4, (_) => Colors.grey[300]!));
  String turn = 'X';
  String apiUrl = 'http://10.0.2.2:5000';

  Future<void> makeMove(int row, int col) async {
    final response = await http.post(
      Uri.parse('$apiUrl/move'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'row': row, 'col': col, 'level': widget.level}),
    );

    final responseData = json.decode(response.body);

    if (responseData['board'] != null) {
      setState(() {
        board = (responseData['board'] as List).map((row) => List<String>.from(row)).toList();
        if (responseData.containsKey('turn')) {
          turn = responseData['turn'];
        }

        // Update colors based on the board state
        for (int r = 0; r < 4; r++) {
          for (int c = 0; c < 4; c++) {
            if (board[r][c] == 'X') {
              colors[r][c] = Colors.blueAccent.withOpacity(0.7);
            } else if (board[r][c] == 'O') {
              colors[r][c] = Colors.redAccent.withOpacity(0.7);
            } else {
              colors[r][c] = Colors.grey[300]!;
            }
          }
        }
      });
    }

    // Check for win or draw and display appropriate message
    if (responseData['status'] == 'win') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showMessage('${responseData['winner']} wins!');
      });
    } else if (responseData['status'] == 'draw') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showMessage('It\'s a draw!');
      });
    }
  }

  Future<void> resetGame() async {
    final response = await http.post(Uri.parse('$apiUrl/reset'));
    final responseData = json.decode(response.body);
    setState(() {
      board = List.generate(4, (_) => List.generate(4, (_) => ''));
      colors = List.generate(4, (_) => List.generate(4, (_) => Colors.grey[300]!));
      if (responseData.containsKey('turn')) {
        turn = responseData['turn'];
      }
    });
  }

  void showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Game Over'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tic Tac Toe - ${widget.level}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Turn: $turn', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  int row = index ~/ 4;
                  int col = index % 4;

                  return GestureDetector(
                    onTap: () => makeMove(row, col),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors[row][col], // Use pre-calculated color
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          board[row][col],
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: resetGame,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32), backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Reset Game', style: TextStyle(fontSize: 18, color:Colors.white)), 
              ),
            ],
          ),
        ),
      ),
    );
  }
}
