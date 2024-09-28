enum ToBackendMessages {
  newLetterProblemRequest,
}

enum ToAppMessages {
  gameStateRequest,
  pardonRequest,
  boostRequest,
  fireworksRequest,
  attemptTheBigHeist,
}

enum ToFrontendMessages {
  gameState,
  pardonResponse,
  boostResponse,
}
