import 'dart:io';

// Run after flutter create. Adds network access to generated platform wrappers.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync()) {
    var xml = manifest.readAsStringSync();
    if (!xml.contains('android.permission.INTERNET')) {
      xml = xml.replaceFirst('<application',
          '<uses-permission android:name="android.permission.INTERNET" />\n    <application');
      manifest.writeAsStringSync(xml);
      stdout.writeln('Android: INTERNET permission added.');
    }
  }

  for (final kind in ['DebugProfile', 'Release']) {
    final file = File('macos/Runner/$kind.entitlements');
    if (!file.existsSync()) continue;
    var xml = file.readAsStringSync();
    if (!xml.contains('com.apple.security.network.client')) {
      xml = xml.replaceFirst('</dict>',
          '  <key>com.apple.security.network.client</key>\n  <true/>\n</dict>');
      file.writeAsStringSync(xml);
      stdout.writeln('macOS: outgoing network access added to $kind.entitlements.');
    }
  }

  // A freshly generated default test references Flutter's template MyApp.
  // Remove that untouched test only; never remove a real existing widget test.
  final defaultTest = File('test/widget_test.dart');
  if (defaultTest.existsSync()) {
    final source = defaultTest.readAsStringSync();
    if (source.contains('MyApp()') && source.contains('Counter increments smoke test')) {
      defaultTest.deleteSync();
      stdout.writeln('Removed incompatible generated counter template test.');
    }
  }
  stdout.writeln('Platform preparation complete.');
}
