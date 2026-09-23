import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../theme/evuddy.dart';

enum VoiceKind { name, phone, email, aadhaar, license, free }

class VoiceFill {
  static final SpeechToText _speech = SpeechToText();
  static bool _ready = false;

  static Future<bool> ensure() async {
    if (_ready) return true;
    _ready = await _speech.initialize();
    return _ready;
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

  /// Pulls name / mobile / email from one spoken sentence for the register form.
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

  Future<void> _tap() async {
    final ok = await VoiceFill.ensure();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone is not available on this device.')),
      );
      return;
    }
    if (listening) {
      await VoiceFill._speech.stop();
      setState(() => listening = false);
      return;
    }
    setState(() => listening = true);
    try {
      await VoiceFill._speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: 'en_IN',
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
        ),
        onResult: (r) {
          if (!r.finalResult && r.recognizedWords.length < 3) return;
          if (r.finalResult) {
            widget.onResult(VoiceFill.extract(r.recognizedWords, widget.kind));
            if (mounted) setState(() => listening = false);
          }
        },
      );
    } catch (_) {
      if (mounted) setState(() => listening = false);
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
