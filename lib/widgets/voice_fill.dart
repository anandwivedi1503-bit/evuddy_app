import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../theme/evuddy.dart';

enum VoiceKind { name, phone, email, aadhaar, license, free }

class VoiceFill {
  static final SpeechToText _speech = SpeechToText();
  static bool _ready = false;
  static String? localeId;

  static Future<bool> ensure({void Function(String message)? onError}) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      onError?.call('Allow microphone in system settings to speak the form.');
      return false;
    }
    if (_ready && _speech.isAvailable) return true;
    _ready = await _speech.initialize(
      onError: (e) => onError?.call(_friendly(e.errorMsg)),
      onStatus: (_) {},
    );
    if (!_ready) {
      onError?.call('Speech is not set up on this phone. Install Google app / Speech Services.');
      return false;
    }
    localeId = await _pickLocale();
    return true;
  }

  static Future<String?> _pickLocale() async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return null;
      const prefer = ['en_IN', 'en-IN', 'hi_IN', 'en_US', 'en_GB', 'en'];
      for (final want in prefer) {
        final needle = want.toLowerCase().replaceAll('-', '_');
        for (final l in locales) {
          final id = l.localeId.toLowerCase().replaceAll('-', '_');
          if (id == needle || id.startsWith('${needle}_') || id.startsWith(needle)) {
            return l.localeId;
          }
        }
      }
      return locales.first.localeId;
    } catch (_) {
      return null;
    }
  }

  static String _friendly(String code) {
    switch (code) {
      case 'error_permission':
        return 'Microphone permission was denied.';
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return 'This emulator has no speech language pack. Use a device or install Google Speech.';
      case 'error_network':
      case 'error_network_timeout':
        return 'Speech needs a network connection.';
      case 'error_no_match':
        return 'Didn’t catch that. Tap the mic and speak again.';
      case 'error_speech_timeout':
        return 'No speech heard. Hold closer to the mic.';
      case 'error_client':
      case 'error_busy':
        return 'Speech service is busy. Close Google Assistant and retry.';
      default:
        return 'Could not start the microphone ($code).';
    }
  }

  static String extract(String spoken, VoiceKind kind) {
    var t = spoken.trim();
    t = t.replaceAll(RegExp(r'^(my name is|name is|i am|this is|fill|enter)\s+', caseSensitive: false), '');
    switch (kind) {
      case VoiceKind.phone:
        final d = t.replaceAll(RegExp(r'\D'), '');
        if (d.length >= 10) return d.substring(d.length - 10);
        return d;
      case VoiceKind.aadhaar:
        final d = t.replaceAll(RegExp(r'\D'), '');
        if (d.length >= 12) return d.substring(0, 12);
        return d;
      case VoiceKind.email:
        return t
            .toLowerCase()
            .replaceAll(' at the rate ', '@')
            .replaceAll(' at ', '@')
            .replaceAll(' dot ', '.')
            .replaceAll(' ', '');
      case VoiceKind.license:
        return t.toUpperCase().replaceAll(' ', '');
      case VoiceKind.name:
        return t.replaceAll(RegExp(r'\s+'), ' ');
      case VoiceKind.free:
        return t;
    }
  }

  static Map<String, String> parseRegister(String spoken) {
    final out = <String, String>{};
    final digits = spoken.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      out['phone'] = digits.replaceAll(RegExp(r'^91'), '');
      if (out['phone']!.length > 10) {
        out['phone'] = out['phone']!.substring(out['phone']!.length - 10);
      }
    }
    final emailMatch = RegExp(
      r'([A-Za-z0-9._%+-]+(?:\s+at\s+|\s*@\s*)[A-Za-z0-9.-]+(?:\s+dot\s+|\.)[A-Za-z]{2,})',
      caseSensitive: false,
    ).firstMatch(spoken);
    if (emailMatch != null) {
      out['email'] = extract(emailMatch.group(0)!, VoiceKind.email);
    }
    var namePart = spoken;
    namePart = namePart.replaceAll(RegExp(r'\b(mobile|phone|number|email|mail)[:\s].*', caseSensitive: false), '');
    namePart = namePart.replaceAll(RegExp(r'\d'), ' ');
    namePart = extract(namePart, VoiceKind.name);
    if (namePart.length >= 3) out['name'] = namePart;
    return out;
  }
}

class VoiceMicButton extends StatefulWidget {
  const VoiceMicButton({
    super.key,
    required this.kind,
    required this.onResult,
    this.tooltip = 'Speak to fill',
  });

  final VoiceKind kind;
  final ValueChanged<String> onResult;
  final String tooltip;

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton> {
  bool listening = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _tap() async {
    if (listening) {
      await VoiceFill._speech.stop();
      setState(() => listening = false);
      return;
    }
    final ok = await VoiceFill.ensure(onError: _toast);
    if (!ok) return;
    setState(() => listening = true);
    try {
      await VoiceFill._speech.listen(
        onResult: (r) {
          final words = r.recognizedWords.trim();
          if (words.length < 2) return;
          if (r.finalResult || words.length >= 3) {
            widget.onResult(VoiceFill.extract(words, widget.kind));
          }
          if (r.finalResult && mounted) setState(() => listening = false);
        },
        listenOptions: SpeechListenOptions(
          localeId: VoiceFill.localeId,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => listening = false);
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _tap,
      icon: Icon(
        listening ? Icons.mic_rounded : Icons.mic_none_rounded,
        color: listening ? Evuddy.magenta : Evuddy.greenDeep,
      ),
    );
  }
}
