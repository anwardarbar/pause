import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../input/voice_input_service.dart';

final voiceInputServiceProvider = Provider<VoiceInputService>(
  (ref) {
    final service = VoiceInputService();
    ref.onDispose(service.dispose);
    return service;
  },
  name: 'voiceInputServiceProvider',
);
