enum GameStatus {
  isRunning,
  isOver,
}

enum NeedRedraw {
  grid,
  score,
  playerList,
}

enum RevealResult {
  hit,
  miss,
  outsideGrid,
  alreadyRevealed,
  unrecognizedUser,
  gameOver,
}
