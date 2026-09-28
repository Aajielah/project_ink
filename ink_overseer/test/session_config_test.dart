import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ink_overseer/models/session_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionConfig Tests', () {
    test('Cooldown duration calculation for 1-hour session is 30 minutes', () async {
      await SessionConfig.triggerCooldown(
        sessionDurationMinutes: 60,
        isTestMode: false,
      );

      final expiry = await SessionConfig.getCooldownExpiry();
      expect(expiry, isNotNull);

      final diff = expiry!.difference(DateTime.now());
      // Should be approximately 30 minutes (29 to 30)
      expect(diff.inMinutes >= 29 && diff.inMinutes <= 30, isTrue);
    });

    test('Cooldown duration calculation for 2-hour session is 60 minutes', () async {
      await SessionConfig.triggerCooldown(
        sessionDurationMinutes: 120,
        isTestMode: false,
      );

      final expiry = await SessionConfig.getCooldownExpiry();
      expect(expiry, isNotNull);

      final diff = expiry!.difference(DateTime.now());
      // Should be approximately 60 minutes (59 to 60)
      expect(diff.inMinutes >= 59 && diff.inMinutes <= 60, isTrue);
    });

    test('Cooldown duration in Test Mode is 1 minute', () async {
      await SessionConfig.triggerCooldown(
        sessionDurationMinutes: 5,
        isTestMode: true,
      );

      final expiry = await SessionConfig.getCooldownExpiry();
      expect(expiry, isNotNull);

      final diff = expiry!.difference(DateTime.now());
      // Should be <= 1 minute
      expect(diff.inMinutes <= 1, isTrue);
    });

    test('Schedule save, retrieval, and clear cycle works accurately', () async {
      final targetTime = DateTime.now().add(const Duration(hours: 2));
      await SessionConfig.saveSchedule(
        startTime: targetTime,
        durationMinutes: 90,
        isTestMode: false,
      );

      final schedule = await SessionConfig.getSchedule();
      expect(schedule, isNotNull);
      expect(schedule!['durationMinutes'], 90);
      expect(schedule['isTestMode'], isFalse);

      await SessionConfig.clearSchedule();
      final cleared = await SessionConfig.getSchedule();
      expect(cleared, isNull);
    });
  });
}
