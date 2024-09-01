enum ToEbsMessages {
  newLetterProblemRequest,
  disconnect;
}

enum FromEbsMessages {
  isConnected,
  newLetterProblemGenerated,
  genericMessage,
  noBroadcasterIdException,
  invalidAlgorithmException,
  invalidTimeoutException,
  invalidConfigurationException,
  unkownMessageException;
}
