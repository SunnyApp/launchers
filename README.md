# launchers

[![pub package](https://img.shields.io/pub/v/launchers.svg)](https://pub.dartlang.org/packages/launchers)
[![Coverage Status](https://coveralls.io/repos/github/SunnyApp/launchers/badge.svg?branch=master)](https://coveralls.io/github/SunnyApp/launchers?branch=master)

A Flutter plugin that makes it easy to link into other apps, including email, sms, WhatsApp, etc.
This plugin is extensible, but a list of included providers can be found at the bottom of this README:

### Usage

#### By provider

You can open a specific provider (or app)
```
final Email email = Email(
  body: "Hello, world",
  subject: "My first message",
  recipients: ["mrroboto@gmail.com"],
  attachmentPath: attachment,
);

/// In this case, [gmailProvider] is one of the packaged providers that comes with the plugin.  You 
/// can also register your own
LaunchService().launchProvider(gmailProvider.providerKey, email);
```

#### By operation

You can also specify an operation and the plugin will attempt to find a suitable launcher:
```
final Email email = Email(
  body: "Hello, world",
  subject: "My first message",
  recipients: ["mrroboto@gmail.com"],
  attachmentPath: attachment,
);

/// In this case [composeEmailOperation] is a statically defined operation schema that a provider 
/// can 'implement'.  Out of the box, there are two providers for email, a native email provider that 
/// opens the devices defaul mail program, or the GMail app
final results = await LaunchService().launch(composeEmailOperation, email);
```

### Included Providers

* sms 
* phone 
* facebook 
* gmail 
* instagram 
* twitter 
* linkedin 
* snapchat 
* pinterest 
* paypal 
* cashapp 
* venmo 



