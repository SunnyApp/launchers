import 'package:equatable/equatable.dart';

import 'link_providers.dart';

enum LaunchResult {
  openedApp,
  openedWeb,
  noProvider,
  unsupported,
  error,
  invalidInput
}
enum SendResult { sent, cancelled, unknown, failed }

/// The base class for this library.  This class represents a service that can be opened on the phone, focusing on
/// a particular user, represented by [handle].  Additionally, it may accept [LaunchInput] parameters to further
/// customize the view that was initialized.  This class can be subclassed to represent a particular type of operation,
/// like sending email, and the user can then register particular handlers for that operation.
abstract class LaunchProvider<I, R extends LaunchResponse> {
  /// A key representing the provider itself.
  ProviderKey get providerKey;

  /// This represents the underlying operation.  In some cases, it's the same as the provider, but it could also represent
  /// something abstract, like sending email, or opening up a certain type of link
  OperationKey<I, R> get operationKey;

  /// Launches this app, and returns the appropriate launch response
  Future<R> launch([I input]);

  /// Creates the appropriate error object
  R error(Object e);

  /// Tags allow us to assign an arbitrary meaning to each launch provider.  For example, if it's a social media profile
  Set<String> get tags;
}

class LaunchResults<L extends LaunchResponse> {
  L _mainResponse;
  ProviderKey _handledBy;
  final bool _frozen;

  final Map<ProviderKey, L> _otherResponses;

  LaunchResults(this._mainResponse, this._handledBy, this._otherResponses)
      : _frozen = true;

  LaunchResults.builder()
      : _mainResponse = null,
        _otherResponses = {},
        _frozen = false;

  LaunchResults.single(L response, [ProviderKey provider])
      : assert(response != null),
        _mainResponse = response,
        _handledBy = provider,
        _frozen = true,
        _otherResponses = {};

  bool get isSuccessful => _mainResponse?.didLaunch;
  Map<ProviderKey, L> get otherResponses => {..._otherResponses};

  L get mainResult => _mainResponse;

  operator []=(ProviderKey key, L result) {
    assert(result != null);
    _checkMutable();
    if (_mainResponse != null) {
      _otherResponses[_handledBy] = _mainResponse;
    }
    _mainResponse = result;
    _handledBy = key;
  }

  LaunchResults<L> freeze() {
    return LaunchResults(_mainResponse, _handledBy, _otherResponses);
  }

  _checkMutable() {
    if (_frozen) throw "Immutable instance cannot be modified";
  }

  Map<ProviderKey, L> get allAttempts => {
        _handledBy: _mainResponse,
        ..._otherResponses,
      };
}

abstract class LaunchResponse {
  LaunchResult get launchResult;

  factory LaunchResponse.ofLinkOpen(LaunchResult launchResult) =>
      _LinkOpenResponse(launchResult);
}

class _LinkOpenResponse implements LaunchResponse {
  final LaunchResult launchResult;

  const _LinkOpenResponse(this.launchResult);

  bool get isSuccessful {
    return launchResult == LaunchResult.openedApp ||
        launchResult == LaunchResult.openedWeb;
  }

  String toString() => "linkOpen: $launchResult";
}

abstract class CommunicationResponse implements LaunchResponse {
  LaunchResult get launchResult;

  SendResult get sendResult;

  factory CommunicationResponse.ofStatus(
      LaunchResult launchResult, SendResult sendResult) {
    return _CommunicationResponse(launchResult, sendResult);
  }

  factory CommunicationResponse.cancelled([LaunchResult launchResult]) =>
      _CommunicationResponse(
          launchResult ?? LaunchResult.openedApp, SendResult.cancelled);

  factory CommunicationResponse.sent([LaunchResult launchResult]) =>
      _CommunicationResponse(
          launchResult ?? LaunchResult.openedApp, SendResult.sent);

  factory CommunicationResponse.unknown([LaunchResult launchResult]) =>
      _CommunicationResponse(
          launchResult ?? LaunchResult.openedApp, SendResult.unknown);

  factory CommunicationResponse.failed(
          [Object error, StackTrace stackTrace, LaunchResult launchResult]) =>
      _CommunicationResponse(launchResult ?? LaunchResult.openedApp,
          SendResult.failed, error, stackTrace);

  factory CommunicationResponse.ofLinkOpen(LinkLaunchResponse linkOpen) {
    return _CommunicationResponse(linkOpen.launchResult, SendResult.unknown);
  }
}

class _CommunicationResponse implements CommunicationResponse {
  final LaunchResult launchResult;
  final SendResult sendResult;
  final Object error;
  final StackTrace stackTrace;

  _CommunicationResponse(this.launchResult, this.sendResult,
      [this.error, this.stackTrace])
      : assert(launchResult != null),
        assert(sendResult != null);

  @override
  String toString() {
    return 'communication: launch:$launchResult; send: $sendResult ${(error != null ? "error: $error" : "")}';
  }
}

class ProviderKey<I, R extends LaunchResponse> extends Equatable {
  final String name;

  factory ProviderKey.sanitized(String name) {
    if (name == null) return null;
    return ProviderKey(name.toLowerCase().trim());
  }

  const ProviderKey(this.name) : assert(name != null);

  @override
  List<Object> get props => [name];

  String toString() {
    return "provider[$name]: [$I, $R]";
  }
}

abstract class OperationKey<I, R extends LaunchResponse> {
  String get name;

  factory OperationKey.sanitized(String name) {
    if (name == null) return null;
    return _OperationKey(name.toLowerCase().trim());
  }

  factory OperationKey(String name) => _OperationKey(name);
}

class _OperationKey<I, R extends LaunchResponse> extends Equatable
    implements OperationKey<I, R> {
  final String name;

  const _OperationKey(this.name) : assert(name != null);

  @override
  List<Object> get props => [name];

  @override
  String toString() {
    return 'operation[$name]: [$I, $R]';
  }
}

extension LaunchResponseExt on LaunchResponse {
  bool get didLaunch =>
      this.launchResult == LaunchResult.openedApp ||
      this.launchResult == LaunchResult.openedWeb;
}
