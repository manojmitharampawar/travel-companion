import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_companion/core/services/location_service.dart';
import 'package:travel_companion/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dayBeforeReminder = true;
  bool _hoursBeforeReminder = true;
  bool _autoStartTracking = true;
  String _alarmDistance = '15'; // km

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dayBeforeReminder = prefs.getBool('dayBeforeReminder') ?? true;
      _hoursBeforeReminder = prefs.getBool('hoursBeforeReminder') ?? true;
      _autoStartTracking = prefs.getBool('autoStartTracking') ?? true;
      _alarmDistance = prefs.getString('alarmDistance') ?? '15';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Reminders Section
          _SectionHeader(title: 'Notifications'),
          _SettingCard(
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.notifications_active,
                  iconColor: AppTheme.warningColor,
                  title: 'Day before reminder',
                  subtitle: 'Get notified 24 hours before your journey',
                  trailing: Switch(
                    value: _dayBeforeReminder,
                    onChanged: (value) {
                      setState(() => _dayBeforeReminder = value);
                      _saveSetting('dayBeforeReminder', value);
                    },
                  ),
                ),
                Divider(color: Colors.grey[100], height: 0),
                _SettingItem(
                  icon: Icons.notifications,
                  iconColor: AppTheme.accentColor,
                  title: 'Hours before reminder',
                  subtitle: 'Get notified 3 hours before departure',
                  trailing: Switch(
                    value: _hoursBeforeReminder,
                    onChanged: (value) {
                      setState(() => _hoursBeforeReminder = value);
                      _saveSetting('hoursBeforeReminder', value);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tracking Section
          _SectionHeader(title: 'Journey Tracking'),
          _SettingCard(
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.my_location,
                  iconColor: AppTheme.successColor,
                  title: 'Auto-start tracking',
                  subtitle: 'Automatically start GPS tracking when near boarding station',
                  trailing: Switch(
                    value: _autoStartTracking,
                    onChanged: (value) {
                      setState(() => _autoStartTracking = value);
                      _saveSetting('autoStartTracking', value);
                    },
                  ),
                ),
                Divider(color: Colors.grey[100], height: 0),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.infoColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.location_on,
                                        size: 18,
                                        color: AppTheme.infoColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Alarm distance',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 44),
                                  child: Text(
                                    'Sound alarm when $_alarmDistance km from destination',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _alarmDistance,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: '5', child: Text('5 km')),
                                DropdownMenuItem(value: '10', child: Text('10 km')),
                                DropdownMenuItem(value: '15', child: Text('15 km')),
                                DropdownMenuItem(value: '20', child: Text('20 km')),
                                DropdownMenuItem(value: '30', child: Text('30 km')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _alarmDistance = value);
                                  _saveSetting('alarmDistance', value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Permissions Section
          _SectionHeader(title: 'Permissions'),
          _SettingCard(
            child: _SettingItem(
              icon: Icons.location_on_outlined,
              iconColor: AppTheme.dangerColor,
              title: 'Location Permission',
              subtitle: 'Required for journey tracking and alerts',
              trailing: ElevatedButton(
                onPressed: _checkLocationPermission,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: AppTheme.infoColor,
                ),
                child: const Text(
                  'Check',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),

          // About Section
          _SectionHeader(title: 'About'),
          _SettingCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.train,
                              size: 24,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Travel Companion',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Version 1.0.0',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Never miss your stop again — Sleep worry-free on Indian trains with GPS-based arrival alerts.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _checkLocationPermission() async {
    final service = LocationService();
    final hasPermission = await service.checkAndRequestPermission();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasPermission
                ? '✓ Location permission granted'
                : '✗ Location permission denied. Please enable it in Settings.',
          ),
          backgroundColor: hasPermission ? AppTheme.successColor : AppTheme.dangerColor,
        ),
      );
    }
    service.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;

  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}

