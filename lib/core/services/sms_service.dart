import 'dart:io';

import 'package:flutter/services.dart';
import 'package:travel_companion/core/constants/app_constants.dart';

/// Native SMS reading service for Android.
/// Uses platform channel to read SMS inbox.
/// On iOS, SMS reading is not available — use EmailService or manual entry.
class SmsService {
  static const _channel = MethodChannel('com.travelcompanion/sms');

  /// Check if SMS reading is available on this platform
  static bool get isAvailable => Platform.isAndroid;

  /// Read all IRCTC-related SMS messages from the inbox.
  /// Returns a list of maps with 'sender', 'body', 'date' keys.
  static Future<List<Map<String, dynamic>>> readIrctcMessages() async {
    if (!isAvailable) return [];

    try {
      final List<dynamic> messages = await _channel.invokeMethod(
        'getIrctcMessages',
        {'senderIds': AppConstants.irctcSenderIds},
      );
      return messages.map(_parseMessage).toList();
    } on PlatformException catch (e) {
      throw SmsReadException('Failed to read SMS: ${e.message}');
    } on MissingPluginException {
      return [];
    }
  }

  /// Read SMS messages received after a specific timestamp
  static Future<List<Map<String, dynamic>>> readNewIrctcMessages({
    required int afterTimestamp,
  }) async {
    if (!isAvailable) return [];

    try {
      final List<dynamic> messages = await _channel.invokeMethod(
        'getIrctcMessages',
        {
          'senderIds': AppConstants.irctcSenderIds,
          'afterTimestamp': afterTimestamp,
        },
      );
      return messages.map(_parseMessage).toList();
    } on PlatformException catch (e) {
      throw SmsReadException('Failed to read SMS: ${e.message}');
    } on MissingPluginException {
      return [];
    }
  }

  static Map<String, dynamic> _parseMessage(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    return {
      'sender': map['sender'] as String? ?? '',
      'body': map['body'] as String? ?? '',
      'date': map['date'] as int? ?? 0,
    };
  }
}

class SmsReadException implements Exception {
  final String message;
  SmsReadException(this.message);

  @override
  String toString() => 'SmsReadException: $message';
}
