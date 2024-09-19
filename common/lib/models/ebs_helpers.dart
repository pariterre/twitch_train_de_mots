enum ToBackendMessages {
  newLetterProblemRequest,
}

enum ToAppMessages {
  gameStateRequest,
  pardonRequest,
  boostRequest,
}

enum ToFrontendMessages {
  gameState,
  pardonResponse,
  boostResponse,
}
