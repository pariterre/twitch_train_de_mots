enum MiniGames {
  treasureHunt,
  blueberryWar,
  warehouseCleaning,
  fixTracks;

  static List<MiniGames> get betweenRoundsGames => [
        treasureHunt,
        blueberryWar,
        warehouseCleaning,
      ];

  static MiniGames get fixTracksGames => fixTracks;
}
