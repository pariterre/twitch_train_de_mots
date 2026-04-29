import 'dart:async';

class TwoStepRequester {
  final Duration confirmationDuration;

  final Future<bool> Function() _canRequest;
  final Future<void> Function(String playerName) onRequestInitialized;
  final Future<void> Function(
      {required String playerName,
      required bool isConfirmed}) onRequestFinalized;

  String? _playerRequesting;
  Completer<bool>? _requestConfirmationCompleter;

  TwoStepRequester({
    this.confirmationDuration = const Duration(seconds: 15),
    required Future<bool> Function() canRequest,
    required this.onRequestInitialized,
    required this.onRequestFinalized,
  }) : _canRequest = canRequest;

  Future<bool> canRequest({required String playerName}) async {
    return (_playerRequesting == null || _playerRequesting == playerName) &&
        await _canRequest();
  }

  Future<void> initiateRequest({required String playerName}) async {
    if (_playerRequesting != null || !(await _canRequest())) return;

    _playerRequesting = playerName;

    // Give time to actually request
    onRequestInitialized(playerName);
    _requestConfirmationCompleter = Completer<bool>();
    final isConfirmed = await _requestConfirmationCompleter!.future.timeout(
      confirmationDuration,
      onTimeout: () => false,
    );
    onRequestFinalized(playerName: playerName, isConfirmed: isConfirmed);

    // Clean up for next request
    _playerRequesting = null;
    _requestConfirmationCompleter = null;
  }

  Future<void> confirmRequest(
      {required String playerName, required bool isConfirmed}) async {
    if (_playerRequesting != playerName || !(await _canRequest())) return;

    _requestConfirmationCompleter!.complete(isConfirmed);
  }
}
