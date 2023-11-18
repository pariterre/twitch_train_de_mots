import 'package:flutter/material.dart';
import 'package:train_de_mots/models/word_manipulation.dart';

class LeaderBoard extends StatelessWidget {
  const LeaderBoard({super.key, required this.wordProblem});

  final WordProblem? wordProblem;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        color: Colors.blueGrey,
        elevation: 10,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Tableau des meneurs',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildFounderTile(
                      founder: 'Participants', score: 'Score', isTitle: true),
                  const SizedBox(height: 12.0),
                  if (wordProblem?.founders.isNotEmpty ?? false)
                    for (var founder in wordProblem!.founders)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: _buildFounderTile(
                            founder: founder,
                            score: wordProblem!.score(founder).toString()),
                      ),
                ],
              ),
            ),
            if (wordProblem == null)
              const Center(
                  child: Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text('En attente d\'un mot',
                    style: TextStyle(color: Colors.white)),
              )),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }

  Widget _buildFounderTile(
      {required String founder, required String score, bool isTitle = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(founder,
            style: TextStyle(
                color: Colors.white,
                fontWeight: isTitle ? FontWeight.bold : FontWeight.normal)),
        SizedBox(
          width: 40,
          child: Center(
            child: Text(score,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: isTitle ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ],
    );
  }
}
