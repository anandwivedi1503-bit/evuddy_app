import 'package:package_info_plus/package_info_plus.dart';

Future<String> loadEvuddyVersionLabel() async {
  final info = await PackageInfo.fromPlatform();
  final build = info.buildNumber.trim();
  final buildLabel = build.isEmpty ? '' : ' ($build)';
  return 'Evuddy ${info.version}$buildLabel';
}
