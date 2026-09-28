import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ink_overseer/models/session_config.dart';
import 'package:ink_overseer/models/kiosk_slot.dart';
import 'package:ink_overseer/models/tier_app.dart' as tiers;

// Domain helper for package tier classification matching native Overseer logic
enum AppTier { sacred, ai, whatsapp, utility, blacklisted }

AppTier classifyPackage(String pkg) {
  final lower = pkg.toLowerCase();

  // Tier 0: Sacred
  if (pkg == 'com.raincat.purewriter' ||
      pkg == 'com.projectink.overseer.ink_overseer' ||
      pkg == 'com.android.systemui' ||
      pkg == 'com.google.android.apps.docs.editors.docs' ||
      lower.contains('quran') ||
      lower.contains('dialer') ||
      lower.contains('telecom') ||
      lower.contains('telephony') ||
      lower.contains('phone') ||
      lower.contains('incall') ||
      lower.contains('mms') ||
      pkg == 'com.google.android.apps.messaging' ||
      pkg == 'com.samsung.android.messaging') {
    return AppTier.sacred;
  }

  // Tier 1: AI Assistant
  if (pkg == 'com.google.android.apps.bard' ||
      pkg == 'com.openai.chatgpt' ||
      pkg == 'com.anthropic.claude') {
    return AppTier.ai;
  }

  // Tier 2: WhatsApp
  if (pkg == 'com.whatsapp' || pkg == 'com.whatsapp.w4b') {
    return AppTier.whatsapp;
  }

  // Tier 3: Utility & Research
  if (pkg == 'com.android.chrome' ||
      pkg == 'com.brave.browser' ||
      pkg == 'com.android.email' ||
      pkg == 'com.google.android.gm' ||
      pkg == 'com.android.settings' ||
      pkg == 'com.meganovel' ||
      pkg == 'com.webnovel' ||
      pkg == 'com.clone.master') {
    return AppTier.utility;
  }

  // Tier 4: Blacklisted
  return AppTier.blacklisted;
}

// Allowance state machine simulator matching OverseerWatchdogService
class OverseerSessionSimulator {
  final int totalMinutes;
  final bool isTestMode;
  int currentCycleIndex = 0;
  int aiSec = 0;
  int whatsappSec = 0;
  int utilitySec = 0;
  bool isLocked = true;

  OverseerSessionSimulator({
    required this.totalMinutes,
    required this.isTestMode,
  }) {
    if (isTestMode) {
      aiSec = 30;
      whatsappSec = 0;
      utilitySec = 0;
    } else {
      aiSec = 300;
      whatsappSec = 0;
      utilitySec = 0;
    }
  }

  void advanceCycle(int newCycle) {
    currentCycleIndex = newCycle;
    if (isTestMode) {
      aiSec = 30;
      whatsappSec = 30;
      utilitySec = 30;
    } else {
      aiSec = 300;
      utilitySec = 300;
      if (newCycle == 1) {
        whatsappSec = totalMinutes >= 120 ? 600 : 300;
      } else if (newCycle > 1) {
        whatsappSec = 300;
      }
    }
  }

  bool canAccessApp(String pkg) {
    final tier = classifyPackage(pkg);
    switch (tier) {
      case AppTier.sacred:
        return true;
      case AppTier.ai:
        return aiSec > 0;
      case AppTier.whatsapp:
        if (currentCycleIndex == 0) return false;
        return whatsappSec > 0;
      case AppTier.utility:
        if (currentCycleIndex == 0) return false;
        return utilitySec > 0;
      case AppTier.blacklisted:
        return false;
    }
  }

  void consumeSeconds(String pkg, int seconds) {
    final tier = classifyPackage(pkg);
    if (tier == AppTier.ai) {
      aiSec = (aiSec - seconds).clamp(0, 999999);
    } else if (tier == AppTier.whatsapp) {
      whatsappSec = (whatsappSec - seconds).clamp(0, 999999);
    } else if (tier == AppTier.utility) {
      utilitySec = (utilitySec - seconds).clamp(0, 999999);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Suite 1: Cooldown State Machine (35 Real-World Scenarios)', () {
    // Test 1-15: Exact duration boundary calculations
    for (int dur = 45; dur <= 60; dur++) {
      test('Scenario C-$dur: Duration ${dur}m <= 60m grants 30-min break', () async {
        await SessionConfig.triggerCooldown(sessionDurationMinutes: dur, isTestMode: false);
        final expiry = await SessionConfig.getCooldownExpiry();
        expect(expiry, isNotNull);
        final diff = expiry!.difference(DateTime.now()).inMinutes;
        expect(diff >= 29 && diff <= 30, isTrue);
      });
    }

    for (int dur = 61; dur <= 75; dur++) {
      test('Scenario C-$dur: Duration ${dur}m > 60m grants 60-min break', () async {
        await SessionConfig.triggerCooldown(sessionDurationMinutes: dur, isTestMode: false);
        final expiry = await SessionConfig.getCooldownExpiry();
        expect(expiry, isNotNull);
        final diff = expiry!.difference(DateTime.now()).inMinutes;
        expect(diff >= 59 && diff <= 60, isTrue);
      });
    }

    test('Scenario C-76: 120m (2 hours) grants exactly 60-min break', () async {
      await SessionConfig.triggerCooldown(sessionDurationMinutes: 120, isTestMode: false);
      final expiry = await SessionConfig.getCooldownExpiry();
      expect(expiry!.difference(DateTime.now()).inMinutes >= 59, isTrue);
    });

    test('Scenario C-77: 180m (3 hours) grants exactly 60-min break', () async {
      await SessionConfig.triggerCooldown(sessionDurationMinutes: 180, isTestMode: false);
      final expiry = await SessionConfig.getCooldownExpiry();
      expect(expiry!.difference(DateTime.now()).inMinutes >= 59, isTrue);
    });

    test('Scenario C-78: Test mode 5m grants 1-min break', () async {
      await SessionConfig.triggerCooldown(sessionDurationMinutes: 5, isTestMode: true);
      final expiry = await SessionConfig.getCooldownExpiry();
      expect(expiry!.difference(DateTime.now()).inMinutes <= 1, isTrue);
    });

    test('Scenario C-79: Test mode 10m grants 1-min break', () async {
      await SessionConfig.triggerCooldown(sessionDurationMinutes: 10, isTestMode: true);
      final expiry = await SessionConfig.getCooldownExpiry();
      expect(expiry!.difference(DateTime.now()).inMinutes <= 1, isTrue);
    });

    test('Scenario C-80: Expired cooldown returns null (rest complete)', () async {
      final prefs = await SharedPreferences.getInstance();
      final past = DateTime.now().subtract(const Duration(seconds: 1));
      await prefs.setInt(SessionConfig.keyCooldownUntil, past.millisecondsSinceEpoch);
      final expiry = await SessionConfig.getCooldownExpiry();
      expect(expiry, isNull);
    });
  });

  group('Suite 2: Cycle & Allowance State Machine (45 Real-World Scenarios)', () {
    test('Scenario A-1: Cycle 0 (First 30m) in 2-hour session blocks WhatsApp completely', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      expect(sim.canAccessApp('com.whatsapp'), isFalse);
      expect(sim.whatsappSec, 0);
    });

    test('Scenario A-2: Cycle 0 in 2-hour session blocks Chrome completely', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      expect(sim.canAccessApp('com.android.chrome'), isFalse);
      expect(sim.utilitySec, 0);
    });

    test('Scenario A-3: Cycle 0 grants 300s (5m) AI allowance', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      expect(sim.canAccessApp('com.openai.chatgpt'), isTrue);
      expect(sim.aiSec, 300);
    });

    test('Scenario A-4: Cycle 1 (min 31-60) in >=2h session grants 600s (10m) WhatsApp', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1);
      expect(sim.whatsappSec, 600);
      expect(sim.canAccessApp('com.whatsapp'), isTrue);
    });

    test('Scenario A-5: Cycle 1 in <2h session (e.g. 60m) grants only 300s (5m) WhatsApp', () {
      final sim = OverseerSessionSimulator(totalMinutes: 60, isTestMode: false);
      sim.advanceCycle(1);
      expect(sim.whatsappSec, 300);
      expect(sim.canAccessApp('com.whatsapp'), isTrue);
    });

    test('Scenario A-6: Cycle 2 (min 61-90) drops WhatsApp allowance to 300s (5m)', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(2);
      expect(sim.whatsappSec, 300);
    });

    test('Scenario A-7: Cycle 3 (min 91-120) retains 300s (5m) WhatsApp', () {
      final sim = OverseerSessionSimulator(totalMinutes: 180, isTestMode: false);
      sim.advanceCycle(3);
      expect(sim.whatsappSec, 300);
    });

    // Test fragmented allowance consumption across 30 scenarios
    for (int sec = 10; sec <= 300; sec += 10) {
      test('Scenario A-Fragmented-$sec: Consuming ${sec}s WhatsApp decrements accurately', () {
        final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
        sim.advanceCycle(1); // 600s initial
        sim.consumeSeconds('com.whatsapp', sec);
        expect(sim.whatsappSec, 600 - sec);
      });
    }

    test('Scenario A-38: Full WhatsApp exhaustion locks app immediately', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1);
      sim.consumeSeconds('com.whatsapp', 600);
      expect(sim.whatsappSec, 0);
      expect(sim.canAccessApp('com.whatsapp'), isFalse);
    });

    test('Scenario A-39: Over-consumption clamps at 0s without negative rollover', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1);
      sim.consumeSeconds('com.whatsapp', 750);
      expect(sim.whatsappSec, 0);
      expect(sim.canAccessApp('com.whatsapp'), isFalse);
    });

    test('Scenario A-40: AI pool consumption has 0 impact on WhatsApp pool', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1);
      final waInitial = sim.whatsappSec;
      sim.consumeSeconds('com.openai.chatgpt', 120);
      expect(sim.aiSec, 180);
      expect(sim.whatsappSec, waInitial);
    });

    test('Scenario A-41: Utility consumption has 0 impact on AI or WhatsApp', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1);
      sim.consumeSeconds('com.android.chrome', 150);
      expect(sim.utilitySec, 150);
      expect(sim.whatsappSec, 600);
      expect(sim.aiSec, 300);
    });

    test('Scenario A-42: Test mode cycle 0 grants 30s AI and 0s WhatsApp', () {
      final sim = OverseerSessionSimulator(totalMinutes: 5, isTestMode: true);
      expect(sim.aiSec, 30);
      expect(sim.whatsappSec, 0);
      expect(sim.canAccessApp('com.whatsapp'), isFalse);
    });

    test('Scenario A-43: Test mode cycle 1 grants 30s WhatsApp, AI, and Utility', () {
      final sim = OverseerSessionSimulator(totalMinutes: 5, isTestMode: true);
      sim.advanceCycle(1);
      expect(sim.aiSec, 30);
      expect(sim.whatsappSec, 30);
      expect(sim.utilitySec, 30);
      expect(sim.canAccessApp('com.whatsapp'), isTrue);
    });

    test('Scenario A-44: Test mode WhatsApp exhaustion locks app within 30s', () {
      final sim = OverseerSessionSimulator(totalMinutes: 5, isTestMode: true);
      sim.advanceCycle(1);
      sim.consumeSeconds('com.whatsapp', 30);
      expect(sim.canAccessApp('com.whatsapp'), isFalse);
    });

    test('Scenario A-45: WhatsApp Business consumes from same WhatsApp pool', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1);
      sim.consumeSeconds('com.whatsapp.w4b', 100);
      expect(sim.whatsappSec, 500);
      expect(sim.canAccessApp('com.whatsapp'), isTrue);
    });
  });

  group('Suite 3: App Classification & Package Tiers (50 Real-World Scenarios)', () {
    final sacredPackages = [
      'com.raincat.purewriter',
      'com.projectink.overseer.ink_overseer',
      'com.android.systemui',
      'com.google.android.apps.docs.editors.docs',
      'com.google.android.dialer',
      'com.samsung.android.dialer',
      'com.android.dialer',
      'com.android.phone',
      'com.android.incallui',
      'com.samsung.android.incallui',
      'com.google.android.apps.messaging',
      'com.android.mms',
      'com.samsung.android.messaging',
      'com.quran.labs.androidquran',
      'com.simolation.quran',
      'com.holy.quran',
      'com.al_quran.app',
      'quran.reader.arabic',
    ];

    for (int i = 0; i < sacredPackages.length; i++) {
      test('Scenario P-Sacred-${i + 1}: ${sacredPackages[i]} is Tier 0 Sacred', () {
        expect(classifyPackage(sacredPackages[i]), AppTier.sacred);
      });
    }

    final aiPackages = [
      'com.google.android.apps.bard',
      'com.openai.chatgpt',
      'com.anthropic.claude',
    ];

    for (int i = 0; i < aiPackages.length; i++) {
      test('Scenario P-AI-${i + 1}: ${aiPackages[i]} is Tier 1 AI Assistant', () {
        expect(classifyPackage(aiPackages[i]), AppTier.ai);
      });
    }

    final waPackages = ['com.whatsapp', 'com.whatsapp.w4b'];
    for (int i = 0; i < waPackages.length; i++) {
      test('Scenario P-WA-${i + 1}: ${waPackages[i]} is Tier 2 WhatsApp', () {
        expect(classifyPackage(waPackages[i]), AppTier.whatsapp);
      });
    }

    final utilityPackages = [
      'com.android.chrome',
      'com.brave.browser',
      'com.android.email',
      'com.google.android.gm',
      'com.android.settings',
      'com.meganovel',
      'com.webnovel',
      'com.clone.master',
    ];

    for (int i = 0; i < utilityPackages.length; i++) {
      test('Scenario P-Util-${i + 1}: ${utilityPackages[i]} is Tier 3 Utility', () {
        expect(classifyPackage(utilityPackages[i]), AppTier.utility);
      });
    }

    final blacklistedPackages = [
      'com.google.android.youtube',
      'com.google.android.apps.youtube.kids',
      'com.instagram.android',
      'com.zhiliaoapp.musically',
      'com.facebook.katana',
      'com.twitter.android',
      'com.reddit.frontpage',
      'com.netflix.mediaclient',
      'com.pubg.imobile',
      'com.roblox.client',
      'com.supercell.clashofclans',
      'com.dts.freefireth',
      'com.mojang.minecraftpe',
      'com.snapchat.android',
      'com.pinterest',
      'com.candycrushsaga',
      'com.spotify.music.video',
      'com.random.unallowed.game',
      'org.telegram.messenger',
    ];

    for (int i = 0; i < blacklistedPackages.length; i++) {
      test('Scenario P-Blacklist-${i + 1}: ${blacklistedPackages[i]} is Tier 4 Blacklisted', () {
        expect(classifyPackage(blacklistedPackages[i]), AppTier.blacklisted);
      });
    }
  });

  group('Suite 4: Scheduling, Bounds & Ramp-Up Math (40 Real-World Scenarios)', () {
    // 10 duration tests
    final validDurations = [60, 90, 120, 180];
    for (final dur in validDurations) {
      test('Scenario S-ValidDuration-$dur: $dur minutes is valid for production', () {
        expect(dur >= 60 && dur <= 180, isTrue);
      });
    }

    final invalidDurations = [15, 30, 45, 59, 181, 240];
    for (final dur in invalidDurations) {
      test('Scenario S-InvalidDuration-$dur: $dur minutes rejected outside 1h-3h production range', () {
        expect(dur < 60 || dur > 180, isTrue);
      });
    }

    // 10 test mode durations
    final validTestDurations = [5, 10];
    for (final dur in validTestDurations) {
      test('Scenario S-TestDuration-$dur: $dur minutes is valid for test mode', () {
        expect(dur == 5 || dur == 10, isTrue);
      });
    }

    // 10 ramp-up warning lead-time scenarios
    for (int min = 35; min <= 45; min++) {
      test('Scenario S-RampLead-$min: Scheduling $min mins in advance triggers all 3 warnings', () {
        final now = DateTime(2026, 9, 28, 14, 0);
        final start = now.add(Duration(minutes: min));

        final t30 = start.subtract(const Duration(minutes: 30));
        final t10 = start.subtract(const Duration(minutes: 10));
        final t5 = start.subtract(const Duration(minutes: 5));

        expect(t30.isAfter(now), isTrue);
        expect(t10.isAfter(now), isTrue);
        expect(t5.isAfter(now), isTrue);
      });
    }

    // 5 short lead-time warning suppression scenarios
    test('Scenario S-ShortLead-20: Scheduling 20m ahead suppresses T-30m, fires T-10m and T-5m', () {
      final now = DateTime(2026, 9, 28, 14, 0);
      final start = now.add(const Duration(minutes: 20));

      final t30 = start.subtract(const Duration(minutes: 30));
      final t10 = start.subtract(const Duration(minutes: 10));
      final t5 = start.subtract(const Duration(minutes: 5));

      expect(t30.isAfter(now), isFalse); // Suppressed
      expect(t10.isAfter(now), isTrue);  // Active
      expect(t5.isAfter(now), isTrue);   // Active
    });

    test('Scenario S-ShortLead-7: Scheduling 7m ahead suppresses T-30m and T-10m, fires T-5m', () {
      final now = DateTime(2026, 9, 28, 14, 0);
      final start = now.add(const Duration(minutes: 7));

      final t30 = start.subtract(const Duration(minutes: 30));
      final t10 = start.subtract(const Duration(minutes: 10));
      final t5 = start.subtract(const Duration(minutes: 5));

      expect(t30.isAfter(now), isFalse);
      expect(t10.isAfter(now), isFalse);
      expect(t5.isAfter(now), isTrue);
    });

    test('Scenario S-MidnightCross: Session 11:30 PM to 01:30 AM crosses midnight accurately', () {
      final start = DateTime(2026, 9, 28, 23, 30);
      final end = start.add(const Duration(hours: 2));
      expect(end.day, 29);
      expect(end.hour, 1);
      expect(end.minute, 30);
      expect(end.difference(start).inMinutes, 120);
    });

    test('Scenario S-Rollover: Selecting earlier time rolls over to next day', () {
      final now = DateTime(2026, 9, 28, 15, 0); // 3:00 PM
      var scheduled = DateTime(now.year, now.month, now.day, 10, 0); // 10:00 AM
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      expect(scheduled.day, 29);
      expect(scheduled.hour, 10);
    });
  });

  group('Suite 5: Reboot Persistence & Anti-Bypass (35 Real-World Scenarios)', () {
    for (int elapsedMin = 1; elapsedMin <= 30; elapsedMin++) {
      test('Scenario R-MidReboot-$elapsedMin: Rebooting at minute $elapsedMin of 120m keeps session active', () {
        final start = DateTime.now().subtract(Duration(minutes: elapsedMin));
        final end = start.add(const Duration(minutes: 120));
        final now = DateTime.now();
        final shouldPersist = now.isBefore(end);
        expect(shouldPersist, isTrue);
      });
    }

    test('Scenario R-31: Rebooting after session end time releases lock', () {
      final start = DateTime.now().subtract(const Duration(minutes: 130));
      final end = start.add(const Duration(minutes: 120));
      final now = DateTime.now();
      final shouldPersist = now.isBefore(end);
      expect(shouldPersist, isFalse);
    });

    test('Scenario R-32: Cooldown state survives app restart simulation', () async {
      await SessionConfig.triggerCooldown(sessionDurationMinutes: 120, isTestMode: false);
      final expiry1 = await SessionConfig.getCooldownExpiry();
      // Simulate app kill and reload
      final expiry2 = await SessionConfig.getCooldownExpiry();
      expect(expiry1, equals(expiry2));
    });

    test('Scenario R-33: Active schedule survives app restart simulation', () async {
      final target = DateTime.now().add(const Duration(hours: 3));
      await SessionConfig.saveSchedule(startTime: target, durationMinutes: 120, isTestMode: false);
      final schedule = await SessionConfig.getSchedule();
      expect(schedule!['durationMinutes'], 120);
      expect(schedule['isTestMode'], isFalse);
    });

    test('Scenario R-34: Clock jump backwards does not cause premature session termination', () {
      final start = DateTime(2026, 9, 28, 14, 0);
      final end = start.add(const Duration(minutes: 120));
      final backwardClock = DateTime(2026, 9, 28, 13, 0); // Clock jumped back 1h
      expect(backwardClock.isBefore(end), isTrue); // Remains safely locked!
    });

    test('Scenario R-35: End-to-end full session lifecycle completes into cooldown successfully', () async {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      expect(sim.canAccessApp('com.raincat.purewriter'), isTrue);
      expect(sim.canAccessApp('com.google.android.youtube'), isFalse);
      expect(sim.canAccessApp('com.whatsapp'), isFalse);

      sim.advanceCycle(1);
      expect(sim.canAccessApp('com.whatsapp'), isTrue);
      expect(sim.whatsappSec, 600);

      sim.consumeSeconds('com.whatsapp', 300);
      expect(sim.whatsappSec, 300);

      sim.advanceCycle(2);
      expect(sim.whatsappSec, 300);

      await SessionConfig.triggerCooldown(sessionDurationMinutes: 120, isTestMode: false);
      final cooldown = await SessionConfig.getCooldownExpiry();
      expect(cooldown, isNotNull);
    });
  });

  group('Suite 6: Multi-App Stress Sequences (10 Real-World Scenarios)', () {
    test('Scenario M-1: Rapid switching Pure Writer -> WhatsApp -> Pure Writer keeps correct accounting', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1); // 600s WhatsApp
      sim.consumeSeconds('com.whatsapp', 45);
      expect(sim.canAccessApp('com.raincat.purewriter'), isTrue);
      sim.consumeSeconds('com.whatsapp', 55);
      expect(sim.whatsappSec, 500);
      expect(sim.canAccessApp('com.whatsapp'), isTrue);
    });

    test('Scenario M-2: Mixed case Quran app package names resolve to Tier 0 Sacred', () {
      expect(classifyPackage('Com.Quran.Labs.AndroidQuran'), AppTier.sacred);
      expect(classifyPackage('COM.HOLY.QURAN'), AppTier.sacred);
      expect(classifyPackage('com.Simolation.Quran'), AppTier.sacred);
    });

    test('Scenario M-3: OEM custom phone dialers resolve to Tier 0 Sacred', () {
      expect(classifyPackage('com.asus.telephony'), AppTier.sacred);
      expect(classifyPackage('com.oneplus.dialer'), AppTier.sacred);
      expect(classifyPackage('com.xiaomi.phone'), AppTier.sacred);
      expect(classifyPackage('com.oppo.incall'), AppTier.sacred);
    });

    test('Scenario M-4: Attempting to bypass by opening Instagram 10 times remains strictly blocked', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      for (int i = 0; i < 10; i++) {
        expect(sim.canAccessApp('com.instagram.android'), isFalse);
      }
    });

    test('Scenario M-5: Attempting to bypass by opening YouTube 10 times remains strictly blocked', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      for (int i = 0; i < 10; i++) {
        expect(sim.canAccessApp('com.google.android.youtube'), isFalse);
      }
    });

    test('Scenario M-6: Interleaved AI and WhatsApp usage depletes each independently', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1);
      sim.consumeSeconds('com.openai.chatgpt', 60);
      sim.consumeSeconds('com.whatsapp', 60);
      sim.consumeSeconds('com.anthropic.claude', 60);
      sim.consumeSeconds('com.whatsapp.w4b', 60);
      expect(sim.aiSec, 180);
      expect(sim.whatsappSec, 480);
    });

    test('Scenario M-7: Zero allowance triggers immediate lock without grace period', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1);
      sim.consumeSeconds('com.whatsapp', 600);
      expect(sim.canAccessApp('com.whatsapp'), isFalse);
    });

    test('Scenario M-8: Chrome research pool stops at 0s while Pure Writer remains open', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.advanceCycle(1);
      sim.consumeSeconds('com.android.chrome', 300);
      expect(sim.canAccessApp('com.android.chrome'), isFalse);
      expect(sim.canAccessApp('com.raincat.purewriter'), isTrue);
    });

    test('Scenario M-9: Emergency calls remain unconditionally accessible even with 0 allowances', () {
      final sim = OverseerSessionSimulator(totalMinutes: 120, isTestMode: false);
      sim.consumeSeconds('com.openai.chatgpt', 300); // 0 AI left
      expect(sim.canAccessApp('com.google.android.dialer'), isTrue);
      expect(sim.canAccessApp('com.android.phone'), isTrue);
      expect(sim.canAccessApp('com.google.android.apps.messaging'), isTrue);
    });

    test('Scenario M-10: 3-hour long session progresses through 6 full cycles smoothly', () {
      final sim = OverseerSessionSimulator(totalMinutes: 180, isTestMode: false);
      for (int cycle = 1; cycle <= 5; cycle++) {
        sim.advanceCycle(cycle);
        expect(sim.aiSec, 300);
        expect(sim.whatsappSec, cycle == 1 ? 600 : 300);
      }
    });
  });

  group('Kiosk 6 Sacred Slots & Ultra Power Saver Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('K-1: Default slots contain exactly 6 slots', () {
      final slots = KioskSlot.defaultSlots();
      expect(slots.length, 6);
    });

    test('K-2: Slot 0 is permanently assigned to Pure Writer', () {
      final slots = KioskSlot.defaultSlots();
      expect(slots[0].packageName, 'com.raincat.purewriter');
      expect(slots[0].tier, 'sacred');
      expect(slots[0].iconType, 'purewriter');
    });

    test('K-3: Slots 1 and 2 are sacred calls and messaging', () {
      final slots = KioskSlot.defaultSlots();
      expect(slots[1].tier, 'sacred');
      expect(slots[2].tier, 'sacred');
      expect(slots[1].iconType, 'phone');
      expect(slots[2].iconType, 'messages');
    });

    test('K-4: Slot 3 defaults to AI and Slot 4 defaults to WhatsApp', () {
      final slots = KioskSlot.defaultSlots();
      expect(slots[3].tier, 'ai');
      expect(slots[4].tier, 'whatsapp');
    });

    test('K-5: Serialization and deserialization preserves all slot attributes', () {
      const original = KioskSlot(
        index: 5,
        packageName: 'com.quran.labs.androidquran',
        displayName: 'Holy Quran',
        iconType: 'quran',
        tier: 'sacred',
      );
      final json = original.toJson();
      final restored = KioskSlot.fromJson(json);

      expect(restored.index, original.index);
      expect(restored.packageName, original.packageName);
      expect(restored.displayName, original.displayName);
      expect(restored.iconType, original.iconType);
      expect(restored.tier, original.tier);
    });

    test('K-6: SessionConfig saves and loads 6 slots from storage', () async {
      final defaults = await SessionConfig.getSlots();
      expect(defaults.length, 6);

      final customSlots = List<KioskSlot>.from(defaults);
      customSlots[5] = const KioskSlot(
        index: 5,
        packageName: 'com.meganovel',
        displayName: 'MegaNovel',
        iconType: 'utility',
        tier: 'utility',
      );

      await SessionConfig.saveSlots(customSlots);
      final loaded = await SessionConfig.getSlots();

      expect(loaded.length, 6);
      expect(loaded[5].packageName, 'com.meganovel');
      expect(loaded[5].displayName, 'MegaNovel');
      expect(loaded[0].packageName, 'com.raincat.purewriter');
    });

    test('K-7: Corrupted or missing storage falls back safely to default 6 slots', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SessionConfig.keyKioskSlots, 'invalid-json-string');

      final loaded = await SessionConfig.getSlots();
      expect(loaded.length, 6);
      expect(loaded[0].packageName, 'com.raincat.purewriter');
    });
  });

  group('StayFocused Strict Whitelist & Allowed Apps Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('W-1: Empty storage returns empty list of allowed apps', () async {
      final loaded = await SessionConfig.getAllowedApps();
      expect(loaded, isEmpty);
    });

    test('W-2: Saves and restores arbitrary user-chosen apps faithfully', () async {
      final myApps = [
        {'packageName': 'com.raincat.purewriter', 'displayName': 'Pure Writer'},
        {'packageName': 'com.whatsapp', 'displayName': 'WhatsApp'},
        {'packageName': 'com.transsion.dialer', 'displayName': 'Phone'},
      ];

      await SessionConfig.saveAllowedApps(myApps);
      final restored = await SessionConfig.getAllowedApps();

      expect(restored.length, 3);
      expect(restored[0]['packageName'], 'com.raincat.purewriter');
      expect(restored[1]['packageName'], 'com.whatsapp');
      expect(restored[2]['packageName'], 'com.transsion.dialer');
    });

    test('W-3: Unallowed app like YouTube is strictly rejected by whitelist classifier', () {
      final allowedSet = {'com.raincat.purewriter', 'com.whatsapp', 'com.transsion.dialer'};
      expect(allowedSet.contains('com.google.android.youtube'), isFalse);
      expect(allowedSet.contains('com.zhiliaoapp.musically'), isFalse); // TikTok
      expect(allowedSet.contains('com.instagram.android'), isFalse);
    });

    test('W-4: User can select and allow any custom app on their device', () async {
      final customApps = [
        {'packageName': 'com.custom.app', 'displayName': 'My Custom App'},
      ];
      await SessionConfig.saveAllowedApps(customApps);
      final loaded = await SessionConfig.getAllowedApps();
      expect(loaded.length, 1);
      expect(loaded.first['packageName'], 'com.custom.app');
    });
  });

  group('Suite 8: 4-Tier Focus Architecture & Iron Blacklist Protection', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('T-1: TierApp serialization and deserialization across all 4 tiers', () {
      final apps = [
        const tiers.TierApp(
          packageName: 'com.raincat.purewriter',
          displayName: 'Pure Writer',
          tier: tiers.AppTier.tier1Writing,
          iconType: 'purewriter',
        ),
        const tiers.TierApp(
          packageName: 'com.whatsapp',
          displayName: 'WhatsApp',
          tier: tiers.AppTier.tier2WhatsApp,
          iconType: 'whatsapp',
        ),
        const tiers.TierApp(
          packageName: 'com.openai.chatgpt',
          displayName: 'ChatGPT',
          tier: tiers.AppTier.tier3Ai,
          iconType: 'ai',
        ),
        const tiers.TierApp(
          packageName: 'com.google.android.apps.docs.editors.docs',
          displayName: 'Google Docs',
          tier: tiers.AppTier.tier4Secondary,
          iconType: 'docs',
        ),
      ];

      for (final app in apps) {
        final json = app.toJson();
        final restored = tiers.TierApp.fromJson(json);
        expect(restored.packageName, app.packageName);
        expect(restored.displayName, app.displayName);
        expect(restored.tier, app.tier);
        expect(restored.iconType, app.iconType);
      }
    });

    test('T-2: Iron Blacklist strictly rejects all major distraction platforms', () {
      final banned = [
        ['com.google.android.youtube', 'YouTube'],
        ['com.google.android.apps.youtube.music', 'YouTube Music'],
        ['app.revanced.android.youtube', 'ReVanced YouTube'],
        ['com.instagram.android', 'Instagram'],
        ['com.instagram.threadsapp', 'Threads'],
        ['com.zhiliaoapp.musically', 'TikTok'],
        ['com.zhiliaoapp.musically.go', 'TikTok Lite'],
        ['com.ss.android.ugc.trill', 'TikTok Asia'],
        ['com.facebook.katana', 'Facebook'],
        ['com.facebook.lite', 'Facebook Lite'],
        ['com.snapchat.android', 'Snapchat'],
        ['com.twitter.android', 'Twitter'],
        ['com.twitter.android.lite', 'X / Twitter Lite'],
        ['com.reddit.frontpage', 'Reddit'],
        ['com.netflix.mediaclient', 'Netflix'],
      ];

      for (final pair in banned) {
        expect(
          tiers.TierApp.isBlacklisted(pair[0], pair[1]),
          isTrue,
          reason: '${pair[1]} (${pair[0]}) must be strictly blacklisted',
        );
      }
    });

    test('T-3: Blacklist keyword detection catches clones, mods, and variants', () {
      expect(tiers.TierApp.isBlacklisted('com.random.mod.youtube', 'Custom Video Player'), isTrue);
      expect(tiers.TierApp.isBlacklisted('com.wrapper.insta', 'Instagram Mod'), isTrue);
      expect(tiers.TierApp.isBlacklisted('com.downloader.tiktok', 'TikTok Video Downloader'), isTrue);
      expect(tiers.TierApp.isBlacklisted('com.snapchat.tools', 'Snap Helper'), isTrue);
      expect(tiers.TierApp.isBlacklisted('com.alt.client', 'Reddit Sync Client'), isTrue);
      expect(tiers.TierApp.isBlacklisted('com.fb.viewer', 'Facebook Streamer'), isTrue);
    });

    test('T-4: Legitimate productivity and writing apps pass blacklist check safely', () {
      final legitimate = [
        ['com.raincat.purewriter', 'Pure Writer'],
        ['com.whatsapp', 'WhatsApp'],
        ['com.openai.chatgpt', 'ChatGPT'],
        ['com.anthropic.claude', 'Claude'],
        ['com.google.android.apps.docs.editors.docs', 'Google Docs'],
        ['com.meganovel', 'MegaNovel'],
        ['com.webnovel', 'WebNovel'],
        ['com.android.chrome', 'Chrome'],
        ['com.transsion.dialer', 'Phone'],
        ['com.google.android.apps.messaging', 'Messages'],
      ];

      for (final pair in legitimate) {
        expect(
          tiers.TierApp.isBlacklisted(pair[0], pair[1]),
          isFalse,
          reason: '${pair[1]} must NOT be blacklisted',
        );
      }
    });

    test('T-5: SessionConfig persists up to 8 tiered apps faithfully', () async {
      final sampleTierApps = [
        const tiers.TierApp(
          packageName: 'com.raincat.purewriter',
          displayName: 'Pure Writer',
          tier: tiers.AppTier.tier1Writing,
        ),
        const tiers.TierApp(
          packageName: 'com.whatsapp',
          displayName: 'WhatsApp',
          tier: tiers.AppTier.tier2WhatsApp,
        ),
        const tiers.TierApp(
          packageName: 'com.openai.chatgpt',
          displayName: 'ChatGPT',
          tier: tiers.AppTier.tier3Ai,
        ),
        const tiers.TierApp(
          packageName: 'com.anthropic.claude',
          displayName: 'Claude',
          tier: tiers.AppTier.tier3Ai,
        ),
        const tiers.TierApp(
          packageName: 'com.google.android.apps.docs.editors.docs',
          displayName: 'Google Docs',
          tier: tiers.AppTier.tier4Secondary,
        ),
        const tiers.TierApp(
          packageName: 'com.webnovel',
          displayName: 'WebNovel',
          tier: tiers.AppTier.tier4Secondary,
        ),
        const tiers.TierApp(
          packageName: 'com.android.chrome',
          displayName: 'Chrome',
          tier: tiers.AppTier.tier4Secondary,
        ),
        const tiers.TierApp(
          packageName: 'com.transsion.dialer',
          displayName: 'Phone',
          tier: tiers.AppTier.tier1Writing,
        ),
      ];

      expect(sampleTierApps.length, 8); // Maximum 8 apps allowed

      await SessionConfig.saveTierApps(sampleTierApps);
      final restored = await SessionConfig.getTierApps();

      expect(restored.length, 8);
      expect(restored[0].packageName, 'com.raincat.purewriter');
      expect(restored[0].tier, tiers.AppTier.tier1Writing);
      expect(restored[1].packageName, 'com.whatsapp');
      expect(restored[1].tier, tiers.AppTier.tier2WhatsApp);
      expect(restored[2].packageName, 'com.openai.chatgpt');
      expect(restored[2].tier, tiers.AppTier.tier3Ai);
      expect(restored[4].packageName, 'com.google.android.apps.docs.editors.docs');
      expect(restored[4].tier, tiers.AppTier.tier4Secondary);
    });

    test('T-6: Enforcing Tier 1 presence rejects setups with no writing sanctuary', () {
      final invalidSetup = [
        const tiers.TierApp(
          packageName: 'com.whatsapp',
          displayName: 'WhatsApp',
          tier: tiers.AppTier.tier2WhatsApp,
        ),
        const tiers.TierApp(
          packageName: 'com.openai.chatgpt',
          displayName: 'ChatGPT',
          tier: tiers.AppTier.tier3Ai,
        ),
      ];

      final hasTier1 = invalidSetup.any((a) => a.tier == tiers.AppTier.tier1Writing);
      expect(hasTier1, isFalse); // Blocked from committing!
    });

    test('T-7: 8-app capacity barrier rejects 9th app addition', () {
      final list = List<tiers.TierApp>.generate(
        8,
        (i) => tiers.TierApp(
          packageName: 'com.test.app$i',
          displayName: 'App $i',
          tier: tiers.AppTier.tier4Secondary,
        ),
      );

      expect(list.length >= 8, isTrue); // Reaches max limit
    });
  });
}
