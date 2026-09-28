import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/session_config.dart';
import '../models/tier_app.dart';
import '../services/overseer_channel.dart';

class TierSetupScreen extends StatefulWidget {
  const TierSetupScreen({super.key});

  @override
  State<TierSetupScreen> createState() => _TierSetupScreenState();
}

class _TierSetupScreenState extends State<TierSetupScreen> {
  List<Map<String, String>> _installedApps = [];
  final List<TierApp> _tierApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final installed = await OverseerChannel.getInstalledApps();
    final saved = await SessionConfig.getTierApps();

    if (saved.isNotEmpty) {
      _tierApps.addAll(saved);
    } else {
      // Auto-suggest defaults if found on device
      for (final app in installed) {
        final pkg = (app['packageName'] ?? '').toLowerCase();
        final name = (app['displayName'] ?? '').toLowerCase();

        if (pkg.contains('purewriter') || name.contains('pure writer')) {
          _tierApps.add(TierApp(
            packageName: app['packageName']!,
            displayName: app['displayName']!,
            tier: AppTier.tier1Writing,
            iconType: 'purewriter',
          ));
        } else if (pkg.contains('whatsapp')) {
          _tierApps.add(TierApp(
            packageName: app['packageName']!,
            displayName: app['displayName']!,
            tier: AppTier.tier2WhatsApp,
            iconType: 'whatsapp',
          ));
        } else if (pkg.contains('chatgpt') || pkg.contains('bard')) {
          _tierApps.add(TierApp(
            packageName: app['packageName']!,
            displayName: app['displayName']!,
            tier: AppTier.tier3Ai,
            iconType: 'ai',
          ));
        }
      }
    }

    if (mounted) {
      setState(() {
        _installedApps = installed;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAppPickerForTier(AppTier tier) async {
    if (_tierApps.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum capacity reached (8 apps total across all tiers).'),
          backgroundColor: SanctumTheme.amberWarning,
        ),
      );
      return;
    }

    String tierTitle = 'Writing Sanctuary';
    if (tier == AppTier.tier2WhatsApp) tierTitle = 'Social Leash (Phase 1 Locked)';
    if (tier == AppTier.tier3Ai) tierTitle = 'AI Brainstorming Pool (5m)';
    if (tier == AppTier.tier4Secondary) tierTitle = 'Secondary Tools (Unlocks Phase 2)';

    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _installedApps.where((app) {
              final name = (app['displayName'] ?? '').toLowerCase();
              final pkg = (app['packageName'] ?? '').toLowerCase();
              return name.contains(query.toLowerCase()) || pkg.contains(query.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assign to $tierTitle',
                            style: const TextStyle(
                              color: SanctumTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: SanctumTheme.textMuted),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: TextField(
                        onChanged: (val) => setModalState(() => query = val.trim()),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search installed apps...',
                          hintStyle: const TextStyle(color: SanctumTheme.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: SanctumTheme.goldAccent, size: 18),
                          filled: true,
                          fillColor: SanctumTheme.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: SanctumTheme.border),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final app = filtered[i];
                          final pkg = app['packageName'] ?? '';
                          final name = app['displayName'] ?? pkg;
                          final isAlreadyAdded = _tierApps.any((t) => t.packageName == pkg);
                          final isBanned = TierApp.isBlacklisted(pkg, name);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isBanned
                                  ? SanctumTheme.crimsonAlert.withAlpha(40)
                                  : const Color(0xFF21262D),
                              child: Icon(
                                isBanned ? Icons.block : Icons.apps,
                                color: isBanned ? SanctumTheme.crimsonAlert : SanctumTheme.goldAccent,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: isBanned
                                    ? SanctumTheme.crimsonAlert
                                    : (isAlreadyAdded ? SanctumTheme.textMuted : Colors.white),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              isBanned
                                  ? '🚫 Permanent Distraction (Banned)'
                                  : (isAlreadyAdded ? 'Already assigned' : pkg),
                              style: TextStyle(
                                color: isBanned ? SanctumTheme.crimsonAlert : SanctumTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            trailing: isBanned
                                ? const Icon(Icons.not_interested, color: SanctumTheme.crimsonAlert, size: 18)
                                : (isAlreadyAdded
                                    ? const Icon(Icons.check, color: SanctumTheme.emeraldReady, size: 16)
                                    : const Icon(Icons.add_circle_outline, color: SanctumTheme.goldAccent, size: 18)),
                            onTap: () {
                              if (isBanned) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🚨 Blacklisted: $name is permanently banned from writing sanctums.'),
                                    backgroundColor: SanctumTheme.crimsonAlert,
                                  ),
                                );
                                return;
                              }
                              if (isAlreadyAdded) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name is already assigned to a tier.'),
                                    backgroundColor: SanctumTheme.amberWarning,
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(ctx, app);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (selected != null) {
      final pkg = selected['packageName'] ?? '';
      final name = selected['displayName'] ?? pkg;

      String iconType = 'generic';
      if (tier == AppTier.tier1Writing) iconType = 'purewriter';
      if (tier == AppTier.tier2WhatsApp) iconType = 'whatsapp';
      if (tier == AppTier.tier3Ai) iconType = 'ai';
      if (tier == AppTier.tier4Secondary) iconType = 'docs';

      setState(() {
        _tierApps.add(TierApp(
          packageName: pkg,
          displayName: name,
          tier: tier,
          iconType: iconType,
        ));
      });
    }
  }

  void _removeApp(TierApp app) {
    setState(() {
      _tierApps.removeWhere((t) => t.packageName == app.packageName);
    });
  }

  Future<void> _saveAndReturn() async {
    final hasTier1 = _tierApps.any((t) => t.tier == AppTier.tier1Writing);
    if (!hasTier1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tier 1 must have at least 1 primary writing app (e.g. Pure Writer).'),
          backgroundColor: SanctumTheme.amberWarning,
        ),
      );
      return;
    }

    await SessionConfig.saveTierApps(_tierApps);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_tierApps.length} apps locked into 4-Tier Structure.'),
          backgroundColor: SanctumTheme.emeraldReady,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t1Apps = _tierApps.where((t) => t.tier == AppTier.tier1Writing).toList();
    final t2Apps = _tierApps.where((t) => t.tier == AppTier.tier2WhatsApp).toList();
    final t3Apps = _tierApps.where((t) => t.tier == AppTier.tier3Ai).toList();
    final t4Apps = _tierApps.where((t) => t.tier == AppTier.tier4Secondary).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('4-TIER FOCUS ENVIRONMENT'),
        actions: [
          TextButton(
            onPressed: _saveAndReturn,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: SanctumTheme.goldAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SanctumTheme.goldAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Capacity & Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SanctumTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SanctumTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Strict Tier Allocation',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Assign apps to exact distraction rules.',
                              style: TextStyle(color: SanctumTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SanctumTheme.goldAccent.withAlpha(35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: SanctumTheme.goldAccent),
                          ),
                          child: Text(
                            '${_tierApps.length} / 8 Apps',
                            style: const TextStyle(
                              color: SanctumTheme.goldAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TIER 1
                  _buildTierSection(
                    tierNumber: 'TIER 1',
                    title: 'Writing Sanctuary (Unlimited 24/7)',
                    description: 'Primary writing app (Pure Writer). Never locked, unlimited access. Calls & SMS are automatically protected.',
                    color: SanctumTheme.emeraldReady,
                    icon: Icons.edit_note,
                    apps: t1Apps,
                    onAdd: () => _openAppPickerForTier(AppTier.tier1Writing),
                  ),
                  const SizedBox(height: 18),

                  // TIER 2
                  _buildTierSection(
                    tierNumber: 'TIER 2',
                    title: 'The Social Leash (The WhatsApp Rule)',
                    description: '100% LOCKED in Phase 1 (First 30 Mins). Unlocks in Phase 2 for 10 minutes (or 5 mins if < 2h).',
                    color: SanctumTheme.goldAccent,
                    icon: Icons.chat_bubble_outline,
                    apps: t2Apps,
                    onAdd: () => _openAppPickerForTier(AppTier.tier2WhatsApp),
                  ),
                  const SizedBox(height: 18),

                  // TIER 3
                  _buildTierSection(
                    tierNumber: 'TIER 3',
                    title: 'AI Brainstorming Pool (5-Minute Pool Throughout)',
                    description: 'ChatGPT / Gemini / Claude. Available in both Phase 1 and 2 for quick prompt lookups (5m shared pool).',
                    color: Colors.lightBlueAccent,
                    icon: Icons.psychology,
                    apps: t3Apps,
                    onAdd: () => _openAppPickerForTier(AppTier.tier3Ai),
                  ),
                  const SizedBox(height: 18),

                  // TIER 4
                  _buildTierSection(
                    tierNumber: 'TIER 4',
                    title: 'Phase 2 Secondary Tools (Delayed Unlock)',
                    description: 'Google Docs, Chrome / Browser, WebNovel. 100% LOCKED in Phase 1 to prevent browsing rabbit holes. Unlocks in Phase 2.',
                    color: Colors.purpleAccent,
                    icon: Icons.menu_book,
                    apps: t4Apps,
                    onAdd: () => _openAppPickerForTier(AppTier.tier4Secondary),
                  ),
                  const SizedBox(height: 24),

                  // Save Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveAndReturn,
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text('Save ${_tierApps.length} Apps & Lock In Setup'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTierSection({
    required String tierNumber,
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required List<TierApp> apps,
    required VoidCallback onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SanctumTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(100), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tierNumber,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: onAdd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add App', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: SanctumTheme.textSecondary, fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 10),
          if (apps.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No app assigned (Tap Add App)',
                  style: TextStyle(color: SanctumTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: apps.map((app) {
                return Chip(
                  backgroundColor: const Color(0xFF1E222A),
                  side: BorderSide(color: color.withAlpha(120)),
                  label: Text(
                    app.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  deleteIcon: const Icon(Icons.cancel, size: 16, color: SanctumTheme.crimsonAlert),
                  onDeleted: () => _removeApp(app),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
