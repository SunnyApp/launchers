import 'default_providers.dart';
import 'email_providers.dart';
import 'launch_provider_api.dart';
import 'link_providers.dart';

LaunchService _instance;

abstract class LaunchService {
  void registerProvider<I, R extends LaunchResponse>(LaunchProvider<I, R> provider);

  Future<LaunchResults<R>> launch<I, R extends LaunchResponse>(
    OperationKey<I, R> operation,
    I input, [
    ProviderKey<I, R> providerKey,
  ]);

  Future<R> launchProvider<I, R extends LaunchResponse>(ProviderKey<I, R> providerKey, I input);

  bool contains(ProviderKey key);

  List<LaunchProvider> findByTag(String tag);

  Iterable<LaunchProvider> get allProviders;

  factory LaunchService() {
    _instance ??= _LaunchService._();
    return _instance;
  }

  factory LaunchService.newInstance() {
    return _LaunchService._();
  }
}

class _LaunchService implements LaunchService {
  _LaunchService._() {
    [
      smsProvider,
      phoneProvider,
      facebookProvider,
      gmailProvider,
      instagramProvider,
      twitterProvider,
      linkedinProvider,
      snapchatProvider,
      pinterestProvider,
      paypalProvider,
      venmoProvider,
      cashappProvider,
    ].forEach(registerProvider);

    registerProvider(nativeEmailComposeLauncher);
    registerProvider(gmailComposeLauncher);
  }

  final _providers = <ProviderKey, LaunchProvider>{};
  final _operations = <String, OperationKey>{};
  final _operationProviders = <String, List<LaunchProvider>>{};

  Iterable<LaunchProvider> get allProviders => [..._providers.values];

  LaunchProvider<I, R> _findProvider<I, R extends LaunchResponse>(ProviderKey<I, R> provider) {
    final p = _providers[provider];
    return p as LaunchProvider<I, R>;
  }

  List<LaunchProvider<I, R>> _findProviders<I, R extends LaunchResponse>(OperationKey<I, R> operation) {
    _verifyOperation(operation);
    final ps = _operationProviders.putIfAbsent(operation.name, () => <LaunchProvider<I, R>>[]);
    return ps.cast();
  }

  @override
  List<LaunchProvider> findByTag(String tag) {
    return _providers.values.where((value) => value.isSocialProfile).toList();
  }

  @override
  void registerProvider<I, R extends LaunchResponse>(LaunchProvider<I, R> provider) {
    final key = provider.providerKey;
    assert(key != null);
    assert(provider != null);

    _providers[key] = provider;
    if (provider.operationKey != null) {
      final op = provider.operationKey;
      if (_operations.containsKey(op.name)) {
        _verifyOperation(op);
      } else {
        _operations[op.name] = op;
      }
      final providers = _operationProviders.putIfAbsent(op.name, () => <LaunchProvider<I, R>>[]);
      providers.add(provider);
    }
  }

  /// Launches a single provider
  Future<R> launchProvider<I, R extends LaunchResponse>(ProviderKey<I, R> providerKey, I input) async {
    final provider = _findProvider<I, R>(providerKey);
    if (provider == null) throw "No provider found: $providerKey";
    return await provider.launch(input);
  }

  /// Launches an operation using any available providers
  Future<LaunchResults<R>> launch<I, R extends LaunchResponse>(OperationKey<I, R> operation, I input,
      [ProviderKey<I, R> providerKey]) async {
    List<LaunchProvider<I, R>> providers;
    if (providerKey != null) {
      providers = [_findProvider<I, R>(providerKey)];
    } else {
      // find all providers
      providers = _findProviders(operation);
    }

    providers = providers.where((_) => _ != null).toList();
    if (providers.isEmpty) {
      throw NoProviderError("No providers for ${operation.name}");
    }

    var results = LaunchResults<R>.builder();
    for (final p in providers) {
      try {
        final result = await p.launch(input);
        results[p.providerKey] = result;
        if (result.didLaunch) return results;
      } catch (e) {
        results[p.providerKey] = p.error(e);
      }
    }

    results = results.freeze();
    return results;
  }

  void _verifyOperation<I, R extends LaunchResponse>(OperationKey<I, R> operation) {
    assert(_operations[operation.name] == operation);
  }

  @override
  bool contains(ProviderKey key) {
    return _providers.containsKey(key.name);
  }
}

class NoProviderError extends Error {
  final String message;

  NoProviderError(this.message);
}

extension LaunchServiceExt on _LaunchService {
  Future<CommunicationResponse> openNativeEmail(Email email) {
    return this.launchProvider(NativeEmailComposeLauncher.key, email);
  }

  Future<CommunicationResponse> openGmail(Email email) {
    return this.launchProvider(GmailComposeLauncher.key, email);
  }

  Future<LinkLaunchResponse> openLink(ProviderKey<Subject, LinkLaunchResponse> key, String handle,
      [Map<String, dynamic> args]) async {
    return await this.launchProvider(key, Subject(handle, args));
  }

  Future<LinkLaunchResponse> openPhone(String number) => openLink(phone, number);

  Future<LinkLaunchResponse> openSms(String number, {String body}) => openLink(sms, number, {"body": body});

  Future<LinkLaunchResponse> openFacebook(String profileId) => openLink(facebook, profileId);

  Future<LinkLaunchResponse> openInstagram(String profileId) => openLink(instagram, profileId);

  Future<LinkLaunchResponse> openTwitter(String handle) => openLink(twitter, handle);

  Future<LinkLaunchResponse> openLinkedIn(String profileId) => openLink(linkedin, profileId);

  Future<LinkLaunchResponse> openSnapchat(String profileId) => openLink(snapchat, profileId);

  Future<LinkLaunchResponse> openPinterest(String profileId) => openLink(pinterest, profileId);

//  LinkProviderKey get ios => _ios;

  ProviderKey<Subject, LinkLaunchResponse> get sms => smsProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get phone => phoneProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get facebook => facebookProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get gmail => gmailProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get instagram => instagramProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get twitter => twitterProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get linkedin => linkedinProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get snapchat => snapchatProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get pinterest => pinterestProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get paypal => paypalProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get cashapp => cashappProvider.providerKey;

  ProviderKey<Subject, LinkLaunchResponse> get venmo => venmoProvider.providerKey;
}
