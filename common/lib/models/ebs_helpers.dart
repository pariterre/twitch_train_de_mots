enum ToBackendMessages {
  newLetterProblemRequest,
}

enum ToAppMessages {
  gameStateRequest,
  pardonRequest,
  boostRequest,
}

enum ToFrontendMessages {
  streamerHasConnected,
  streamerHasDisconnected,
  gameState,
  pardonResponse,
  boostResponse,
}
