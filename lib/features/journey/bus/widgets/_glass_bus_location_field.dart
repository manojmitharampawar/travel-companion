part of '../add_bus_journey_screen.dart';

class _GlassBusLocationField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final LocationPoint? value;
  final bool isDetecting;
  final ValueChanged<LocationPoint?> onSelected;
  final VoidCallback? onDetectGps;
  final VoidCallback onPickOnMap;

  const _GlassBusLocationField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onSelected,
    required this.onPickOnMap,
    this.onDetectGps,
    this.isDetecting = false,
  });

  @override
  State<_GlassBusLocationField> createState() => _GlassBusLocationFieldState();
}
