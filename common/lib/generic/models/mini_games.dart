enum MiniGames {
  treasureHunt,
  blueberryWar,
  trackFix;

  static List<MiniGames> get betweenRoundsGames => [
        treasureHunt,
        blueberryWar,
      ];

  static List<MiniGames> get endOfRailwayGames => [
        trackFix,
      ];
}
