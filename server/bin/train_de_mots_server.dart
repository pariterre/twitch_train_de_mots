import 'package:train_de_mots_server/letter_problem.dart';
import 'package:train_de_mots_server/problem_generator.dart';
import 'package:train_de_mots_server/problem.dart';
import 'package:train_de_mots_server/range.dart';

void main(List<String> arguments) async {
  final elapsed = <Duration>[];
  final problems = <LetterProblem?>[];

  for (int i = 0; i < 10; i++) {
    print('Generating problem $i');

    final now = DateTime.now();
    problems.add(await ProblemGenerator.generateFromBuildingUp(
      Problem(
        lengthShortestSolution: Range(4, 4),
        lengthLongestSolution: Range(8, 12),
        nbSolutions: Range(20, 40),
        nbUselessLetters: 0,
      ),
    ));
    elapsed.add(DateTime.now().difference(now));
  }

  for (int i = 0; i < problems.length; i++) {
    print('Problem $i: ${problems[i]}');
  }

  final meanTime =
      elapsed.reduce((value, element) => value + element).inMilliseconds /
          problems.length;
  print('Mean time to generate (${problems.length}) : $meanTime ms');
}
