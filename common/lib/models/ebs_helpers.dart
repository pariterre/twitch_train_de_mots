import 'dart:convert';

import 'package:common/models/exceptions.dart';

class MessageProtocol {
  final MessageTargets? target;
  final FromToMessages fromTo;

  final Map<String, dynamic>? data;
  final bool? isSuccess;
  final Map<String, dynamic>? internalMain;
  final Map<String, dynamic>? internalIsolate;

  MessageProtocol({
    this.target,
    required this.fromTo,
    this.data,
    this.isSuccess,
    this.internalMain,
    this.internalIsolate,
  });

  Map<String, dynamic> toJson() => {
        'target': target?.index,
        'from_to': fromTo.getIndex,
        'from_to_type': fromTo._fromToType.index,
        'data': data,
        'is_success': isSuccess,
        'internal_main': internalMain,
        'internal_isolate': internalIsolate,
      };
  String encode() => jsonEncode(toJson());

  factory MessageProtocol.fromJson(Map<String, dynamic> json) {
    return MessageProtocol(
      target:
          json['target'] == null ? null : MessageTargets.values[json['target']],
      fromTo:
          _FromToTypes.values[json['from_to_type']].toFromTo(json['from_to']),
      data: json['data'],
      isSuccess: json['is_success'],
      internalMain: json['internal_main'],
      internalIsolate: json['internal_isolate'],
    );
  }

  factory MessageProtocol.decode(String raw) {
    return MessageProtocol.fromJson(jsonDecode(raw));
  }

  MessageProtocol copyWith({
    MessageTargets? target,
    FromToMessages? fromTo,
    Map<String, dynamic>? data,
    bool? isSuccess,
    Map<String, dynamic>? internalMain,
    Map<String, dynamic>? internalIsolate,
  }) {
    target ??= this.target;
    fromTo ??= this.fromTo;
    data ??= this.data;
    isSuccess ??= this.isSuccess;
    internalMain ??= this.internalMain;
    internalIsolate ??= this.internalIsolate;

    return MessageProtocol(
      target: target,
      fromTo: fromTo,
      data: data,
      isSuccess: isSuccess,
      internalMain: internalMain,
      internalIsolate: internalIsolate,
    );
  }
}

enum MessageTargets {
  main,
  client,
  frontend;
}

mixin FromToMessages {
  int get getIndex;
  List<FromToMessages> get getValues;
  _FromToTypes get _fromToType;
}

enum _FromToTypes {
  mainToEbs,
  clientToEbs,
  frontendToEbs,
  ebsToMain,
  ebsToClient,
  ebsToFrontend;

  FromToMessages toFromTo(int index) {
    switch (this) {
      case _FromToTypes.mainToEbs:
        return FromMainToEbsMessages.values[index];
      case _FromToTypes.clientToEbs:
        return FromClientToEbsMessages.values[index];
      case _FromToTypes.frontendToEbs:
        return FromFrontendToEbsMessages.values[index];
      case _FromToTypes.ebsToMain:
        return FromEbsToMainMessages.values[index];
      case _FromToTypes.ebsToClient:
        return FromEbsToClientMessages.values[index];
      case _FromToTypes.ebsToFrontend:
        return FromEbsToFrontendMessages.values[index];
    }
  }
}

enum FromMainToEbsMessages implements FromToMessages {
  getUserId,
  getDisplayName,
  getLogin;

  @override
  int get getIndex => index;

  @override
  List<FromToMessages> get getValues => values;

  @override
  _FromToTypes get _fromToType => _FromToTypes.mainToEbs;
}

enum FromClientToEbsMessages implements FromToMessages {
  newLetterProblemRequest,
  pardonStatusUpdate,
  pardonRequestStatus,
  pong,
  disconnect;

  @override
  int get getIndex => index;

  @override
  List<FromToMessages> get getValues => values;
  @override
  _FromToTypes get _fromToType => _FromToTypes.clientToEbs;
}

enum FromFrontendToEbsMessages implements FromToMessages {
  registerToGame,
  pardonRequest;

  factory FromFrontendToEbsMessages.fromString(String name) {
    try {
      return FromFrontendToEbsMessages.values
          .firstWhere((e) => name.contains(e.name));
    } catch (e) {
      throw InvalidEndpointException();
    }
  }

  @override
  int get getIndex => index;

  @override
  List<FromToMessages> get getValues => values;
  @override
  _FromToTypes get _fromToType => _FromToTypes.frontendToEbs;

  String asEndpoint() => '/$name';
}

enum FromEbsToMainMessages implements FromToMessages {
  initialize,
  responseInternal,
  getUserId,
  getDisplayName,
  getLogin,
  canDestroyIsolated;

  @override
  int get getIndex => index;

  @override
  List<FromToMessages> get getValues => values;
  @override
  _FromToTypes get _fromToType => _FromToTypes.ebsToMain;
}

enum FromEbsToClientMessages implements FromToMessages {
  isConnected,
  ping,
  newLetterProblemGenerated,
  pardonRequest,
  noBroadcasterIdException,
  invalidAlgorithmException,
  invalidTimeoutException,
  invalidConfigurationException,
  unkownMessageException,
  disconnect;

  @override
  int get getIndex => index;

  @override
  List<FromToMessages> get getValues => values;
  @override
  _FromToTypes get _fromToType => _FromToTypes.ebsToClient;
}

enum FromEbsToFrontendMessages implements FromToMessages {
  ping,
  gameStarted,
  pardonStatusUpdate,
  gameEnded;

  @override
  int get getIndex => index;

  @override
  List<FromToMessages> get getValues => values;
  @override
  _FromToTypes get _fromToType => _FromToTypes.ebsToFrontend;
}

enum FromEbsToGeneric implements FromToMessages {
  response,
  error;

  @override
  int get getIndex => index;

  @override
  List<FromToMessages> get getValues => values;
  @override
  _FromToTypes get _fromToType => _FromToTypes.ebsToFrontend;
}
