import 'package:flutter/material.dart';

class SolutionsDisplayer extends StatefulWidget {
  const SolutionsDisplayer({super.key, required this.solutions});

  final List<String> solutions;

  @override
  State<SolutionsDisplayer> createState() => _SolutionsDisplayerState();
}

class _SolutionsDisplayerState extends State<SolutionsDisplayer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var word in widget.solutions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _Word(word: word),
          ),
      ],
    );
  }
}

class _Word extends StatelessWidget {
  const _Word({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    // Create a letter that ressemble those on a Scrabble board
    return SizedBox(
      width: 100,
      child: Center(child: Text(word)),
    );
  }
}
