import 'package:flutter_test/flutter_test.dart';
import 'package:launchers/launchers.dart';

void main() {
  test("Launch Gmail", () {
    LaunchService().launchProvider(
        gmailProvider.providerKey, Email(subject: 'My first email'));
  });
}
