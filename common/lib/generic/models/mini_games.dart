enum MiniGames {
  treasureHunt,
  blueberryWar,
  fixTracks;

  static List<MiniGames> get betweenRoundsGames => [
        treasureHunt,
        blueberryWar,
      ];

  static MiniGames get fixTracksGames => fixTracks;
}
