import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/services/location_service.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';

class CheckLocationPermissionAction {
  const CheckLocationPermissionAction._();

  static Future<void> execute(BuildContext context) async {
    final service = LocationService();
    final hasPermission = await service.checkAndRequestPermission();

    if (context.mounted) {
      AdaptiveFeedback.showToast(
        context,
        hasPermission
            ? 'Location permission granted'
            : 'Location permission denied. Enable it in system settings.',
        isError: !hasPermission,
      );
    }

    service.dispose();
  }
}
