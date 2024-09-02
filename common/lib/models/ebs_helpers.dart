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

enum FrontendHttpGetEndpoints {
  initialize;

  factory FrontendHttpGetEndpoints.fromString(String value) {
    final name = value.substring(1);
    return FrontendHttpGetEndpoints.values
        .firstWhere((element) => element.toString() == name);
  }

  @override
  String toString() => '/${super.toString()}';
}

enum FrontendHttpPostEndpoints {
  pardon;

  factory FrontendHttpPostEndpoints.fromString(String value) {
    final name = value.substring(1);
    return FrontendHttpPostEndpoints.values
        .firstWhere((element) => element.toString() == name);
  }

  @override
  String toString() => '/${super.toString()}';
}
