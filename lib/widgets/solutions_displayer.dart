import 'package:flutter/material.dart';
import 'package:train_de_mots/models/misc.dart';

class SolutionsDisplayer extends StatefulWidget {
  const SolutionsDisplayer({super.key, required this.solutions});

  final List<Solution> solutions;

  @override
  State<SolutionsDisplayer> createState() => _SolutionsDisplayerState();
}

class _SolutionsDisplayerState extends State<SolutionsDisplayer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var solution in widget.solutions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _Solution(solution: solution),
          ),
      ],
    );
  }
}

class _Solution extends StatelessWidget {
  const _Solution({required this.solution});

  final Solution solution;

  @override
  Widget build(BuildContext context) {
    // Create a letter that ressemble those on a Scrabble board
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
          width: 200,
          height: 30,
          child: solution.isFound
              ? Center(
                  child: Text(
                      '${solution.word} (${solution.founder} - ${solution.value} pts)'))
              : Tooltip(
                  message: solution.word,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                )),
    );
  }
}
