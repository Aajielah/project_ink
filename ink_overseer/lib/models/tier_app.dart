enum AppTier {
  tier1Writing,
  tier2WhatsApp,
  tier3Ai,
  tier4Secondary,
}

class TierApp {
  final String packageName;
  final String displayName;
  final AppTier tier;
  final String iconType;

  const TierApp({
    required this.packageName,
    required this.displayName,
    required this.tier,
    this.iconType = 'generic',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'displayName': displayName,
        'tier': tier.index,
        'iconType': iconType,
      };

  factory TierApp.fromJson(Map<String, dynamic> json) => TierApp(
        packageName: json['packageName'] as String,
        displayName: json['displayName'] as String,
        tier: AppTier.values[json['tier'] as int? ?? 0],
        iconType: json['iconType'] as String? ?? 'generic',
      );

  static const Set<String> blacklistedPackages = {
    // YouTube
    'com.google.android.youtube',
    'com.google.android.apps.youtube.music',
    'app.revanced.android.youtube',
    // Instagram & Threads
    'com.instagram.android',
    'com.instagram.threadsapp',
    // TikTok
    'com.zhiliaoapp.musically',
    'com.zhiliaoapp.musically.go',
    'com.ss.android.ugc.trill',
    // Facebook
    'com.facebook.katana',
    'com.facebook.lite',
    'com.facebook.orca',
    // Snapchat
    'com.snapchat.android',
    // Twitter / X
    'com.twitter.android',
    'com.twitter.android.lite',
    // Reddit
    'com.reddit.frontpage',
    // Video streaming
    'com.netflix.mediaclient',
    'com.amazon.avod.thirdpartyclient',
  };

  static bool isBlacklisted(String packageName, String displayName) {
    final lowerPkg = packageName.toLowerCase();
    final lowerName = displayName.toLowerCase();

    for (final blackPkg in blacklistedPackages) {
      if (lowerPkg == blackPkg.toLowerCase()) return true;
    }

    if (lowerPkg.contains('youtube') ||
        lowerPkg.contains('instagram') ||
        lowerPkg.contains('tiktok') ||
        lowerPkg.contains('snapchat') ||
        lowerPkg.contains('facebook') ||
        lowerPkg.contains('reddit') ||
        lowerPkg.contains('netflix') ||
        lowerPkg.contains('twitter') ||
        lowerName.contains('youtube') ||
        lowerName.contains('instagram') ||
        lowerName.contains('tiktok') ||
        lowerName.contains('snapchat') ||
        lowerName.contains('facebook') ||
        lowerName.contains('reddit') ||
        lowerName.contains('netflix') ||
        lowerName.contains('twitter')) {
      return true;
    }

    return false;
  }
}
