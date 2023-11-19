class Letter {
  final String data;
  final int value;

  Letter(this.data) : value = getValueOfLetter(data);

  // The value of the letter is the same as the number of points it gives in Scrabble (French)
  static int getValueOfLetter(String letter) {
    switch (letter) {
      case 'A':
      case 'E':
      case 'I':
      case 'L':
      case 'N':
      case 'O':
      case 'R':
      case 'S':
      case 'T':
      case 'U':
        return 1;
      case 'D':
      case 'G':
      case 'M':
        return 2;
      case 'B':
      case 'C':
      case 'P':
        return 3;
      case 'F':
      case 'H':
      case 'V':
        return 4;
      case 'J':
      case 'Q':
        return 8;
      case 'K':
      case 'W':
      case 'X':
      case 'Y':
      case 'Z':
        return 10;
      default:
        throw 'Invalid letter $letter';
    }
  }
}
