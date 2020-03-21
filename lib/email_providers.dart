import 'dart:async';

import 'package:flutter/services.dart';

import 'default_providers.dart';
import 'launch_provider_api.dart';
import 'link_providers.dart';

/// This file contains the api and implementation for native email and gmail app integration.

abstract class EmailComposeLauncher implements LaunchProvider<Email, CommunicationResponse> {
  @override
  OperationKey<Email, CommunicationResponse> get operationKey => composeEmailOperation;
}

final composeEmailOperation = OperationKey<Email, CommunicationResponse>('composeEmail');

class EmailProviderKey extends ProviderKey<Email, CommunicationResponse> {
  const EmailProviderKey(String name) : super(name);
}

final nativeEmailComposeLauncher = NativeEmailComposeLauncher();
final gmailComposeLauncher = GmailComposeLauncher();

///
/// Launches a native email compose
///
class NativeEmailComposeLauncher extends EmailComposeLauncher {
  static const MethodChannel _channel = MethodChannel('github.com/sunnyapp/launchers_compose');

  @override
  final tags = {Tags.communicationsProvider};

  @override
  Future<CommunicationResponse> launch([Email input]) async {
    try {
      final result = await _channel.invokeMethod<String>('send', input.toJson());
      return emailSendResult(result);
    } catch (e) {
      final error = e;
      if (error is PlatformException && error.code == 'not_available') {
        return CommunicationResponse.ofStatus(LaunchResult.unsupported, SendResult.failed);
      } else {
        return CommunicationResponse.failed(e);
      }
    }
  }

  @override
  EmailProviderKey get providerKey => key;

  static EmailProviderKey get key => const EmailProviderKey('nativeEmail');

  @override
  CommunicationResponse error(Object e) {
    return CommunicationResponse.failed(e);
  }

  @override
  String toString() => 'provider: ${providerKey.name}';
}

///
/// Launches a gmail compose
///
class GmailComposeLauncher extends EmailComposeLauncher {
  @override
  final tags = {Tags.communicationsProvider};

  @override
  Future<CommunicationResponse> launch([Email input]) async {
    final gmailResponse = await gmailProvider.launch(input);
    return CommunicationResponse.ofLinkOpen(gmailResponse);
  }

  @override
  EmailProviderKey get providerKey => key;

  static EmailProviderKey get key => const EmailProviderKey('gmailCompose');

  @override
  CommunicationResponse error(Object e) {
    return CommunicationResponse.failed(e);
  }

  @override
  String toString() => 'provider: ${providerKey.name}';
}

CommunicationResponse emailSendResult(String name) {
  switch (name?.toLowerCase() ?? '') {
    case 'cancelled':
      return CommunicationResponse.cancelled();
    case 'sent':
      return CommunicationResponse.sent();
    case 'unknown':
      return CommunicationResponse.unknown();
    case 'failed':
      return CommunicationResponse.failed();
    default:
      return CommunicationResponse.unknown();
  }
}

class Email implements Subject {
  final String subject;
  final List<String> recipients;
  final List<String> cc;
  final List<String> bcc;
  final String body;
  final String attachmentPath;

  const Email({
    this.subject = '',
    this.recipients = const [],
    this.cc = const [],
    this.bcc = const [],
    this.body = '',
    this.attachmentPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'body': body,
      'recipients': recipients,
      'cc': cc,
      'bcc': bcc,
      'attachment_path': attachmentPath
    };
  }

  @override
  Map<String, dynamic> get args => toJson();

  @override
  String get handle => recipients.firstWhere((_) => true, orElse: () => null);
}
