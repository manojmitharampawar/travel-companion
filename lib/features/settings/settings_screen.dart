import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_companion/core/services/location_service.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/providers/app_providers.dart';

const _kAccent = Color(0xFF3498DB);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dayBeforeReminder = true;
  bool _hoursBeforeReminder = true;
  bool _autoStartTracking = true;
  String _alarmDistance = '15';

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
    final g = GlassColors.of(context);

    return Scaffold(
      backgroundColor: g.bg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background orbs
          const _SettingsBackground(),

          CustomScrollView(
            slivers: [
              // Glass AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                foregroundColor: g.appBarForeground,
                elevation: 0,
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Notifications Section
                    _GlassSectionHeader(title: 'Notifications'),
                    _GlassSettingCard(
                      child: Column(
                        children: [
                          _GlassSettingItem(
                            icon: Icons.notifications_active,
                            iconColor: const Color(0xFFF39C12),
                            title: 'Day before reminder',
                            subtitle:
                                'Get notified 24 hours before your journey',
                            trailing: _glassSwitch(
                              value: _dayBeforeReminder,
                              onChanged: (value) {
                                setState(() => _dayBeforeReminder = value);
                                _saveSetting('dayBeforeReminder', value);
                              },
                            ),
                          ),
                          Divider(
                            color: g.divider,
                            height: 0,
                          ),
                          _GlassSettingItem(
                            icon: Icons.notifications,
                            iconColor: const Color(0xFF9B59B6),
                            title: 'Hours before reminder',
                            subtitle:
                                'Get notified 3 hours before departure',
                            trailing: _glassSwitch(
                              value: _hoursBeforeReminder,
                              onChanged: (value) {
                                setState(
                                    () => _hoursBeforeReminder = value);
                                _saveSetting(
                                    'hoursBeforeReminder', value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tracking Section
                    _GlassSectionHeader(title: 'Journey Tracking'),
                    _GlassSettingCard(
                      child: Column(
                        children: [
                          _GlassSettingItem(
                            icon: Icons.my_location,
                            iconColor: const Color(0xFF27AE60),
                            title: 'Auto-start tracking',
                            subtitle:
                                'Automatically start GPS tracking when near boarding station',
                            trailing: _glassSwitch(
                              value: _autoStartTracking,
                              onChanged: (value) {
                                setState(
                                    () => _autoStartTracking = value);
                                _saveSetting(
                                    'autoStartTracking', value);
                              },
                            ),
                          ),
                          Divider(
                            color: g.divider,
                            height: 0,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .all(8),
                                                decoration:
                                                    BoxDecoration(
                                                  color: _kAccent
                                                      .withValues(
                                                          alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.location_on,
                                                  size: 18,
                                                  color: _kAccent,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Alarm distance',
                                                style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 15,
                                                  color: g.textAlpha(0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    left: 44),
                                            child: Text(
                                              'Sound alarm when $_alarmDistance km from destination',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: g.textAlpha(0.45),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _kAccent.withValues(
                                            alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _kAccent.withValues(
                                              alpha: 0.25),
                                        ),
                                      ),
                                      child: DropdownButton<String>(
                                        value: _alarmDistance,
                                        underline:
                                            const SizedBox.shrink(),
                                        dropdownColor: g.dropdownBg,
                                        style: TextStyle(
                                          color: g.textAlpha(0.9),
                                          fontSize: 14,
                                        ),
                                        iconEnabledColor: _kAccent,
                                        items: const [
                                          DropdownMenuItem(
                                              value: '5',
                                              child: Text('5 km')),
                                          DropdownMenuItem(
                                              value: '10',
                                              child: Text('10 km')),
                                          DropdownMenuItem(
                                              value: '15',
                                              child: Text('15 km')),
                                          DropdownMenuItem(
                                              value: '20',
                                              child: Text('20 km')),
                                          DropdownMenuItem(
                                              value: '30',
                                              child: Text('30 km')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() =>
                                                _alarmDistance = value);
                                            _saveSetting(
                                                'alarmDistance', value);
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

                    // Appearance Section
                    _GlassSectionHeader(title: 'Appearance'),
                    _GlassSettingCard(
                      child: Column(
                        children: [
                          _GlassSettingItem(
                            icon: Icons.palette_outlined,
                            iconColor: const Color(0xFF9B59B6),
                            title: 'App Theme',
                            subtitle: 'Choose between dark, light, or system default',
                            trailing: _buildThemeModeSelector(),
                          ),
                        ],
                      ),
                    ),

                    // Map Section
                    _GlassSectionHeader(title: 'Map'),
                    _GlassSettingCard(
                      child: Column(
                        children: [
                          _GlassSettingItem(
                            icon: Icons.layers_outlined,
                            iconColor: const Color(0xFF1565C0),
                            title: 'Railway Track Overlay',
                            subtitle:
                                'Show OpenRailwayMap tracks on train journey map',
                            trailing: _glassSwitch(
                              value: ref.watch(railwayOverlayProvider),
                              activeThumbColor: const Color(0xFF1565C0),
                              onChanged: (_) => ref
                                  .read(
                                      railwayOverlayProvider.notifier)
                                  .toggle(),
                            ),
                          ),
                          Divider(
                            color: g.divider,
                            height: 0,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0)
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: Color(0xFF1565C0)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Railway overlay uses OpenRailwayMap tiles (OpenStreetMap data). '
                                    'Requires internet; disable to save data on slow connections.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: g.textAlpha(0.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Permissions Section
                    _GlassSectionHeader(title: 'Permissions'),
                    _GlassSettingCard(
                      child: _GlassSettingItem(
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFFE74C3C),
                        title: 'Location Permission',
                        subtitle:
                            'Required for journey tracking and alerts',
                        trailing: _GlassSmallButton(
                          label: 'Check',
                          color: _kAccent,
                          onTap: _checkLocationPermission,
                        ),
                      ),
                    ),

                    // About Section
                    _GlassSectionHeader(title: 'About'),
                    _GlassSettingCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _kAccent.withValues(
                                        alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.train,
                                    size: 24,
                                    color: _kAccent,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Travel Companion',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: g.textAlpha(0.9),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Version 1.0.0',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: g.textAlpha(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _kAccent.withValues(
                                        alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _kAccent.withValues(
                                          alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    'Never miss your stop again — Sleep worry-free on Indian trains with GPS-based arrival alerts.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _kAccent.withValues(
                                          alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector() {
    final currentMode = ref.watch(themeModeProvider);
    final modes = [
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.system, Icons.settings_brightness_rounded, 'Auto'),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: modes.map((entry) {
        final (mode, icon, label) = entry;
        final isActive = currentMode == mode;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? _kAccent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? _kAccent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isActive
                        ? _kAccent
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? _kAccent
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _glassSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeThumbColor = _kAccent,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeThumbColor,
      activeTrackColor: activeThumbColor.withValues(alpha: 0.35),
      inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
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
                ? 'Location permission granted'
                : 'Location permission denied. Please enable it in Settings.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: hasPermission
              ? const Color(0xFF27AE60)
              : const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    service.dispose();
  }
}

// ─────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _kAccent.withValues(alpha: 0.12),
                  _kAccent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF9B59B6).withValues(alpha: 0.08),
                  const Color(0xFF9B59B6).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────

class _GlassSectionHeader extends StatelessWidget {
  final String title;
  const _GlassSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: _kAccent.withValues(alpha: 0.9),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Setting Card
// ─────────────────────────────────────────────

class _GlassSettingCard extends StatelessWidget {
  final Widget child;
  const _GlassSettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Setting Item
// ─────────────────────────────────────────────

class _GlassSettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _GlassSettingItem({
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
              color: iconColor.withValues(alpha: 0.15),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Small Button
// ─────────────────────────────────────────────

class _GlassSmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlassSmallButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
