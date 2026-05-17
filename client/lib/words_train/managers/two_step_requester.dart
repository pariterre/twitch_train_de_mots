import 'dart:async';

class TwoStepRequester {
  final Duration confirmationDuration;

  final Future<bool> Function() _canRequest;
  final Future<void> Function(String login) onRequestInitialized;
  final Future<void> Function(
      {required String login, required bool isConfirmed}) onRequestFinalized;

  String? _playerRequesting;
  Completer<bool>? _requestConfirmationCompleter;

  TwoStepRequester({
    this.confirmationDuration = const Duration(seconds: 15),
    required Future<bool> Function() canRequest,
    required this.onRequestInitialized,
    required this.onRequestFinalized,
  }) : _canRequest = canRequest;

  Future<bool> canRequest({required String login}) async {
    return (_playerRequesting == null || _playerRequesting == login) &&
        await _canRequest();
  }

  Future<void> initiateRequest({required String login}) async {
    if (_playerRequesting != null || !(await _canRequest())) return;

    _playerRequesting = login;

    // Give time to actually request
    onRequestInitialized(login);
    _requestConfirmationCompleter = Completer<bool>();
    final isConfirmed = await _requestConfirmationCompleter!.future.timeout(
      confirmationDuration,
      onTimeout: () => false,
    );
    onRequestFinalized(login: login, isConfirmed: isConfirmed);

    // Clean up for next request
    _playerRequesting = null;
    _requestConfirmationCompleter = null;
  }

  Future<void> confirmRequest(
      {required String login, required bool isConfirmed}) async {
    if (_playerRequesting != login || !(await _canRequest())) return;

    _requestConfirmationCompleter!.complete(isConfirmed);
  }
}
