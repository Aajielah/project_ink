import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/session_config.dart';
import '../services/overseer_channel.dart';

class AllowedAppsScreen extends StatefulWidget {
  const AllowedAppsScreen({super.key});

  @override
  State<AllowedAppsScreen> createState() => _AllowedAppsScreenState();
}

class _AllowedAppsScreenState extends State<AllowedAppsScreen> {
  List<Map<String, String>> _allApps = [];
  final Set<String> _selectedPackages = {};
  final Map<String, String> _packageToName = {};

  String _searchQuery = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    final installed = await OverseerChannel.getInstalledApps();
    final saved = await SessionConfig.getAllowedApps();

    for (final app in installed) {
      final pkg = app['packageName'] ?? '';
      final name = app['displayName'] ?? '';
      if (pkg.isNotEmpty) {
        _packageToName[pkg] = name;
      }
    }

    if (saved.isNotEmpty) {
      for (final s in saved) {
        final pkg = s['packageName'] ?? '';
        if (pkg.isNotEmpty) {
          _selectedPackages.add(pkg);
        }
      }
    } else {
      // Auto-suggest writing essentials & phone if found
      for (final app in installed) {
        final pkg = (app['packageName'] ?? '').toLowerCase();
        final name = (app['displayName'] ?? '').toLowerCase();
        if (pkg.contains('purewriter') ||
            name.contains('pure writer') ||
            pkg.contains('dialer') ||
            name.contains('phone') ||
            pkg.contains('messaging') ||
            name.contains('messages')) {
          _selectedPackages.add(app['packageName']!);
        }
      }
    }

    if (mounted) {
      setState(() {
        _allApps = installed;
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String pkgName, String displayName) {
    setState(() {
      if (_selectedPackages.contains(pkgName)) {
        _selectedPackages.remove(pkgName);
      } else {
        _selectedPackages.add(pkgName);
        _packageToName[pkgName] = displayName;
      }
    });
  }

  Future<void> _saveAndReturn() async {
    final listToSave = <Map<String, String>>[];
    for (final pkg in _selectedPackages) {
      listToSave.add({
        'packageName': pkg,
        'displayName': _packageToName[pkg] ?? pkg,
      });
    }
    await SessionConfig.saveAllowedApps(listToSave);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedPackages.length} apps saved for Strict Whitelist Mode.',
          ),
          backgroundColor: SanctumTheme.emeraldReady,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allApps.where((app) {
      if (_searchQuery.isEmpty) return true;
      final name = (app['displayName'] ?? '').toLowerCase();
      final pkg = (app['packageName'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || pkg.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('STRICT ALLOWED APPS'),
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
          ? const Center(
              child: CircularProgressIndicator(color: SanctumTheme.goldAccent),
            )
          : Column(
              children: [
                // Info Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFF161B22),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, color: SanctumTheme.goldAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Strict Mode will ONLY allow these ${_selectedPackages.length} apps. Your home screen & all other apps will be blocked.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SanctumTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search installed apps (e.g. Pure Writer, WhatsApp)...',
                      hintStyle: const TextStyle(color: SanctumTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: SanctumTheme.goldAccent, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: SanctumTheme.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: SanctumTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SanctumTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SanctumTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SanctumTheme.goldAccent),
                      ),
                    ),
                  ),
                ),

                // Apps List
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching apps found.',
                            style: TextStyle(color: SanctumTheme.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFF1E222A),
                          ),
                          itemBuilder: (context, i) {
                            final app = filtered[i];
                            final pkg = app['packageName'] ?? '';
                            final name = app['displayName'] ?? pkg;
                            final isChecked = _selectedPackages.contains(pkg);

                            return CheckboxListTile(
                              value: isChecked,
                              activeColor: SanctumTheme.goldAccent,
                              checkColor: SanctumTheme.background,
                              onChanged: (_) => _toggleSelection(pkg, name),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                  color: isChecked ? Colors.white : SanctumTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                pkg,
                                style: const TextStyle(
                                  color: SanctumTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: isChecked
                                    ? SanctumTheme.goldAccent.withAlpha(50)
                                    : const Color(0xFF21262D),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: isChecked ? SanctumTheme.goldAccent : SanctumTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Save Bottom Button
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: const Color(0xFF161B22),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveAndReturn,
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text('Save ${_selectedPackages.length} Allowed Apps'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
