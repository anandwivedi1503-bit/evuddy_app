import 'package:url_launcher/url_launcher.dart';

/// Opens live evuddy.com pages or a phone dialer. Does not touch website source.
Future<bool> openEvuddyPath(String path) {
  final uri = Uri.parse('https://www.evuddy.com$path');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> dialHelpdesk() {
  return launchUrl(Uri.parse('tel:+918726006512'));
}

Future<bool> launchMaps(String query) {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
