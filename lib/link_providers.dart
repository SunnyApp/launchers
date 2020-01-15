import 'package:flutter/material.dart';
import 'package:launchers/default_providers.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart' as url;

import 'launch_provider_api.dart';

/// Knows how to open up a link to an application, with optional parameters.
/// For a list of examples, see `lib/default_providers.dart`, eg [gmailProvider]
class LinkProvider implements LaunchProvider<Subject, LinkLaunchResponse> {
  final ProviderKey<Subject, LinkLaunchResponse> providerKey;
  final OperationKey<Subject, LinkLaunchResponse> operationKey;

  /// A readable label for this provider
  final String typeLabel;

  /// The scheme this app uses - this scheme is typically used to query the underlying os to see if there's an app
  /// that handles the link
  final String scheme;

  /// A callback function to generate a direct app link.  This generator is provided with the handle and arguments, if any
  final LinkFromHandle<Subject> appLinkGenerator;

  /// A callback function to generate a direct web link.  This generator is provided with the handle and arguments, if any
  final LinkFromHandle<Subject> webLinkGenerator;

  final Set<String> tags;

  LinkProvider(this.providerKey,
      {OperationKey<Subject, LinkLaunchResponse> operationKey,
      Set<String> tags,
      this.scheme,
      this.appLinkGenerator,
      this.webLinkGenerator,
      this.typeLabel})
      : tags = {...?tags},
        operationKey = operationKey ??
            OperationKey<Subject, LinkLaunchResponse>(
                "open${providerKey.name}Link");

  @override
  LinkLaunchResponse error(Object e) {
    return LinkLaunchResponse.error(error);
  }

  String get provider => providerKey.name;

  @override
  Future<LinkLaunchResponse> launch([Subject input]) async {
    final log = Logger("links.$provider");
    final handle = input?.handle;
    if (handle == null) {
      return LinkLaunchResponse.invalidInput();
    }
    bool isHttp = handle.startsWith(_httpPrefixPattern);
    final generator = this;
    var appLink = generator.appLinkGenerator(input).toString();
    if (!isHttp && await url.canLaunch(appLink)) {
      log.info("Attempt app link: $appLink");
      final bool nativeAppLaunchSucceeded =
          await url.launch(appLink, statusBarBrightness: Brightness.light);
      log.info("success: $nativeAppLaunchSucceeded for app launch $appLink");
      if (nativeAppLaunchSucceeded == true) {
        return LinkLaunchResponse.openedApp();
      }
      if (nativeAppLaunchSucceeded != true &&
          generator.webLinkGenerator != null) {
        log.info(
            "Native launch for $provider -> $handle failed.  Attempting web launch");
        final webLink = generator.webLinkGenerator(input).toString();
        final response = await url.launch(webLink, forceSafariVC: true);
        log.info("success: $response for web launch $webLink");
        return response
            ? LinkLaunchResponse(LaunchResult.openedWeb)
            : LinkLaunchResponse.unsupported();
      } else if (nativeAppLaunchSucceeded != true) {
        log.info(
            "Native app navigation failed for $provider: $handle, and this provider doesn't support web links");
        return LinkLaunchResponse.unsupported();
      }
    } else if (isHttp || generator.webLinkGenerator != null) {
      log.info(
          "App cannot launch $provider native links, using web link for  $handle");
      final webLink =
          isHttp ? handle : generator.webLinkGenerator(input).toString();
      final webLinkResult = await url.launch(webLink, forceSafariVC: true);
      return webLinkResult
          ? LinkLaunchResponse(LaunchResult.openedWeb)
          : LinkLaunchResponse.unsupported();
    } else {
      log.warning(
          "App can't launch $provider links and no web link could be produced for $handle");
      return LinkLaunchResponse.unsupported();
    }
    return LinkLaunchResponse.unsupported();
  }

  @override
  String toString() => "provider: ${providerKey.name}";
}

/// Launch input parameter that opens a profile or account
abstract class Subject {
  String get handle;
  Map<String, dynamic> get args;

  factory Subject(String handle, Map<String, dynamic> args) {
    return _Subject(handle, args);
  }
}

class LinkProviderKey extends ProviderKey<Subject, LinkLaunchResponse> {
  const LinkProviderKey(String name) : super(name);
}

class _Subject implements Subject {
  final String handle;
  final Map<String, dynamic> args;

  _Subject(this.handle, this.args);
}

final openLinkOperationKey = OperationKey<Subject, LaunchResponse>("openLink");
typedef LinkFromHandle<I extends Subject> = String Function(I input);
typedef ErrorBuilder<R extends LinkLaunchResponse> = R Function(Object error);

class LinkLaunchResponse implements LaunchResponse {
  final LaunchResult launchResult;
  final Object error;
  LinkLaunchResponse(this.launchResult, {this.error})
      : assert(launchResult != null);

  LinkLaunchResponse.invalidInput()
      : error = null,
        launchResult = LaunchResult.invalidInput;
  LinkLaunchResponse.error(this.error) : launchResult = LaunchResult.error;
  LinkLaunchResponse.unsupported() : this(LaunchResult.unsupported);
  LinkLaunchResponse.openedApp() : this(LaunchResult.openedApp);
  LinkLaunchResponse.openedWeb() : this(LaunchResult.openedWeb);
}

final _httpPrefixPattern = RegExp("https?:\/\/", caseSensitive: false);

class Tags {
  Tags._();
  static const socialMedia = "socialMedia";
  static const paymentProvider = "payments";
  static const communicationsProvider = "communications";
}

extension LaunchProviderExt on LaunchProvider {
  bool get isSocialProfile => this.tags.contains(Tags.socialMedia);
  bool get isPayment => this.tags.contains(Tags.paymentProvider);
  bool get isCommunications => this.tags.contains(Tags.communicationsProvider);
}
