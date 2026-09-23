import 'package:evuddy_app/widgets/voice_fill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts phone, email and aadhaar from speech', () {
    expect(VoiceFill.extract('nine eight seven six five four three two one zero', VoiceKind.phone), '');
    expect(VoiceFill.extract('call me on 9876543210 please', VoiceKind.phone), '9876543210');
    expect(VoiceFill.extract('rahul at gmail dot com', VoiceKind.email), 'rahul@gmail.com');
    expect(VoiceFill.extract('1234 5678 9012 extra', VoiceKind.aadhaar), '123456789012');
  });

  test('parses a full register sentence', () {
    final p = VoiceFill.parseRegister(
      'My name is Anand Wivedi mobile 9876543210 email anand at evuddy dot com',
    );
    expect(p['phone'], '9876543210');
    expect(p['email'], 'anand@evuddy.com');
    expect(p['name']!.toLowerCase(), contains('anand'));
  });
}
