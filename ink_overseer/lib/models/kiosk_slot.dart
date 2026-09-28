class KioskSlot {
  final int index; // 0 to 5 (6 slots total)
  final String packageName;
  final String displayName;
  final String iconType; // 'purewriter', 'phone', 'messages', 'ai', 'whatsapp', 'utility', 'quran', 'docs'
  final String tier; // 'sacred', 'ai', 'whatsapp', 'utility'

  const KioskSlot({
    required this.index,
    required this.packageName,
    required this.displayName,
    required this.iconType,
    required this.tier,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'packageName': packageName,
        'displayName': displayName,
        'iconType': iconType,
        'tier': tier,
      };

  factory KioskSlot.fromJson(Map<String, dynamic> json) => KioskSlot(
        index: json['index'] as int,
        packageName: json['packageName'] as String,
        displayName: json['displayName'] as String,
        iconType: json['iconType'] as String? ?? 'utility',
        tier: json['tier'] as String? ?? 'utility',
      );

  static List<KioskSlot> defaultSlots() => const [
        // Slot 1: Pure Writer (Permanent Sacred)
        KioskSlot(
          index: 0,
          packageName: 'com.raincat.purewriter',
          displayName: 'Pure Writer',
          iconType: 'purewriter',
          tier: 'sacred',
        ),
        // Slot 2: Phone (Emergency Calls - Sacred)
        KioskSlot(
          index: 1,
          packageName: 'com.google.android.dialer',
          displayName: 'Phone / Calls',
          iconType: 'phone',
          tier: 'sacred',
        ),
        // Slot 3: Messages / SMS (Emergency - Sacred)
        KioskSlot(
          index: 2,
          packageName: 'com.google.android.apps.messaging',
          displayName: 'Messages',
          iconType: 'messages',
          tier: 'sacred',
        ),
        // Slot 4: AI Writing Assistant (5m Metered Pool)
        KioskSlot(
          index: 3,
          packageName: 'com.openai.chatgpt',
          displayName: 'ChatGPT / Gemini',
          iconType: 'ai',
          tier: 'ai',
        ),
        // Slot 5: WhatsApp (Metered Leash)
        KioskSlot(
          index: 4,
          packageName: 'com.whatsapp',
          displayName: 'WhatsApp',
          iconType: 'whatsapp',
          tier: 'whatsapp',
        ),
        // Slot 6: Choice Utility (Quran / Docs / Chrome / Novel)
        KioskSlot(
          index: 5,
          packageName: 'com.quran.labs.androidquran',
          displayName: 'Quran / Docs',
          iconType: 'quran',
          tier: 'sacred',
        ),
      ];
}
