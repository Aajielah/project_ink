import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/kiosk_slot.dart';
import '../models/session_config.dart';
import '../services/overseer_channel.dart';

class SlotConfigurationScreen extends StatefulWidget {
  const SlotConfigurationScreen({super.key});

  @override
  State<SlotConfigurationScreen> createState() => _SlotConfigurationScreenState();
}

class _SlotConfigurationScreenState extends State<SlotConfigurationScreen> {
  List<KioskSlot> _slots = KioskSlot.defaultSlots();
  List<Map<String, String>> _installedApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loaded = await SessionConfig.getSlots();
    final apps = await OverseerChannel.getInstalledApps();
    if (mounted) {
      setState(() {
        _slots = loaded;
        _installedApps = apps;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectAppForSlot(int slotIndex) async {
    if (slotIndex == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot 1 is permanently reserved for Pure Writer (Your writing sanctuary).'),
          backgroundColor: SanctumTheme.goldAccent,
        ),
      );
      return;
    }

    if (slotIndex == 1 || slotIndex == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slots 2 and 3 are reserved for emergency calls and SMS.'),
          backgroundColor: SanctumTheme.emeraldReady,
        ),
      );
      return;
    }

    // Let user pick from installed apps for Slots 4, 5, 6
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Assign App to Slot ${slotIndex + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SanctumTheme.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: _installedApps.length,
                    itemBuilder: (context, i) {
                      final app = _installedApps[i];
                      return ListTile(
                        title: Text(app['displayName'] ?? '', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(app['packageName'] ?? '', style: const TextStyle(color: SanctumTheme.textMuted, fontSize: 11)),
                        onTap: () => Navigator.pop(ctx, app),
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

    if (selected != null) {
      final pkg = selected['packageName'] ?? '';
      final name = selected['displayName'] ?? '';

      String tier = 'utility';
      String iconType = 'utility';

      if (pkg.contains('chatgpt') || pkg.contains('bard') || pkg.contains('claude')) {
        tier = 'ai';
        iconType = 'ai';
      } else if (pkg.contains('whatsapp')) {
        tier = 'whatsapp';
        iconType = 'whatsapp';
      } else if (pkg.contains('quran')) {
        tier = 'sacred';
        iconType = 'quran';
      } else if (pkg.contains('docs')) {
        tier = 'sacred';
        iconType = 'docs';
      }

      setState(() {
        _slots[slotIndex] = KioskSlot(
          index: slotIndex,
          packageName: pkg,
          displayName: name,
          iconType: iconType,
          tier: tier,
        );
      });

      await SessionConfig.saveSlots(_slots);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUSTOMIZE 6 SACRED SLOTS'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SanctumTheme.goldAccent))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure Your Focus Environment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: SanctumTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Once a writing session starts, these 6 slots are locked in stone and cannot be changed until the session ends.',
                    style: TextStyle(fontSize: 13, color: SanctumTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _slots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final slot = _slots[i];
                        final isLockedSlot = i == 0 || i == 1 || i == 2;
                        return Container(
                          decoration: BoxDecoration(
                            color: SanctumTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SanctumTheme.border),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF21262D),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: SanctumTheme.goldAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              slot.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            subtitle: Text(
                              isLockedSlot
                                  ? 'Fixed Sacred Anchor (${slot.tier.toUpperCase()})'
                                  : '${slot.packageName} • Tap to change',
                              style: TextStyle(
                                color: isLockedSlot ? SanctumTheme.emeraldReady : SanctumTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            trailing: isLockedSlot
                                ? const Icon(Icons.lock, size: 18, color: SanctumTheme.emeraldReady)
                                : const Icon(Icons.edit, size: 18, color: SanctumTheme.goldAccent),
                            onTap: () => _selectAppForSlot(i),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Save Slots & Return'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
