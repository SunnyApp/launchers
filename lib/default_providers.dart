import 'link_providers.dart';

///
/// This file contains all the default link providers.  You can add more providers by registering them in the
/// [LaunchService]
///

const LinkProviderKey _sms = LinkProviderKey('sms');
const LinkProviderKey _phone = LinkProviderKey('phone');
const LinkProviderKey _facebook = LinkProviderKey('facebook');
const LinkProviderKey _gmail = LinkProviderKey('gmail');
const LinkProviderKey _instagram = LinkProviderKey('instagram');
const LinkProviderKey _twitter = LinkProviderKey('twitter');
const LinkProviderKey _linkedin = LinkProviderKey('linkedin');
const LinkProviderKey _snapchat = LinkProviderKey('snapchat');
const LinkProviderKey _pinterest = LinkProviderKey('pinterest');
const LinkProviderKey _paypal = LinkProviderKey('paypal');
const LinkProviderKey _cashapp = LinkProviderKey('cashapp');
const LinkProviderKey _venmo = LinkProviderKey('venmo');
const LinkProviderKey _youtubeChannel = LinkProviderKey('youtubeChannel');
const LinkProviderKey _youtubeVideo = LinkProviderKey('youtubeVideo');

final gmailProvider = LinkProvider(_gmail,
    tags: {Tags.communicationsProvider},
    scheme: 'googlegmail:',
    appLinkGenerator: (input) =>
        "googlegmail://co?to=${input.handle}${_toQueryParams(input.args, prefix: "&", encodeSpaces: false, keys: {
          "subject",
          "body"
        })}");

final phoneProvider = LinkProvider(_phone,
    tags: {},
    scheme: 'tel:',
    appLinkGenerator: (input) => 'tel:${telNumber(input.handle!)}');

final smsProvider = LinkProvider(_sms,
    tags: {Tags.communicationsProvider},
    scheme: 'sms:',
    appLinkGenerator: (input) =>
        "sms:${telNumber(input.handle!)}${_toQueryParams(input.args, keys: {
          "body"
        })}");

final facebookProvider = LinkProvider.basic(
  'facebook',
  appScheme: 'fb://',
  generateAppLink: false,
);

final instagramProvider = LinkProvider.basic(
  'instagram',
  appLinkGenerator: (input) => 'instagram://user?username=${input.handle}',
);

final twitterProvider = LinkProvider.basic('twitter',
    appLinkGenerator: (input) => 'twitter://user?screen_name=${input.handle}',
    webLinkGenerator: (input) {
      final twitterPrefix = (input.handle![0] == '@') ? '' : '@';
      return 'https://twitter.com/$twitterPrefix${input.handle}';
    });

final linkedinProvider = LinkProvider.basic('linkedin',
    appLinkGenerator: (input) => 'linkedin://profile/${input.handle}',
    webLinkGenerator: (input) =>
        'https://www.linkedin.com/in/${input.handle}/');

final snapchatProvider = LinkProvider.basic(
  'snapchat',
  appLinkGenerator: (input) => 'snapchat://add/${input.handle}',
  urlPath: 'add/',
);

final pinterestProvider = LinkProvider.basic(
  'pinterest',
  appLinkGenerator: (input) => 'pinterest://user/${input.handle}',
);

// Cash paying apps
final paypalProvider = LinkProvider(
  _paypal,
  tags: {Tags.socialMedia, Tags.paymentProvider},
  webLinkGenerator: (input) => 'https://paypal.me/${input.handle}',
);

final venmoProvider = LinkProvider(
  _venmo,
  tags: {Tags.socialMedia, Tags.paymentProvider},
  webLinkGenerator: (input) => 'https://venmo.com/${input.handle}',
);

final cashappProvider = LinkProvider(
  _cashapp,
  tags: {Tags.paymentProvider, Tags.socialMedia},
  webLinkGenerator: (input) {
    var handle = input.handle!;
    if (!handle.startsWith('\$')) {
      handle = '\$$handle';
    }
    return 'https://cash.app/$handle';
  },
);

final youtubeVideoProvider = LinkProvider(_youtubeVideo,
    tags: {Tags.socialMedia},
    scheme: 'youtube://',
    handleExtractor: (uri) {
      if (uri.host.contains('youtu') && uri.path.contains('watch')) {
        return uri.queryParameters['v'];
      }
    },
    webLinkGenerator: (input) =>
        "https://www.youtube.com/watch?v=${input.handle}",
    appLinkGenerator: (input) => "youtube://watch?v=${input.handle}");

final youtubeChannelProvider = LinkProvider(_youtubeChannel,
    tags: {Tags.socialMedia},
    scheme: 'youtube://',
    handleExtractor: (uri) {
      if (uri.host.contains('youtu') && uri.path.contains('channel')) {
        return uri.pathSegments.isEmpty ? null : uri.pathSegments.last;
      }
    },
    webLinkGenerator: (input) =>
        "https://www.youtube.com/channel/${input.handle}");

String telNumber(String input) {
  var out = '';

  for (var i = 0; i < input.length; ++i) {
    var char = input[i];
    if (_isNumeric((char))) {
      out += char;
    }
  }
  return out;
}

bool _isNumeric(String str) {
  if (str == null) {
    return false;
  }
  return double.tryParse(str) != null;
}

String _toQueryParams(Map<String, dynamic>? options,
    {Set<String>? keys, String prefix = '?', bool encodeSpaces = true}) {
  final included = (options ?? {})
      .entries
      .where((entry) => keys?.contains(entry.key) ?? true)
      .toList()
      .asMap()
      .map((_, entry) => entry);
  if (included.isEmpty) return '';
  return prefix +
      included.entries.map((entry) {
        final encodedValue = encodeSpaces
            ? Uri.encodeQueryComponent(entry.value.toString())
            : Uri.encodeComponent(entry.value.toString());
        return '${entry.key}=$encodedValue';
      }).join('&');
}
