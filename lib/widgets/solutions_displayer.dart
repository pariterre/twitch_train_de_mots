import 'package:flutter/material.dart';
import 'package:train_de_mots/models/solution.dart';

class SolutionsDisplayer extends StatelessWidget {
  const SolutionsDisplayer({super.key, required this.solutions});

  final Solutions solutions;

  @override
  Widget build(BuildContext context) {
    List<Solutions> solutionsByLength = [];
    for (var i = solutions.nbLettersInSmallest;
        i <= solutions.nbLettersInLongest;
        i++) {
      solutionsByLength.add(solutions.solutionsOfLength(i));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var solutions in solutionsByLength)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Wrap(
              direction: Axis.vertical,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Mots de ${solutions.first.word.length} lettres',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  direction: Axis.vertical,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [...solutions.map((e) => _Solution(solution: e))],
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
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
