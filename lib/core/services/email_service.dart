import 'package:flutter/services.dart';

/// Email reading service for IRCTC booking confirmations.
/// Works on both Android and iOS as a fallback for SMS.
///
/// On iOS, this uses the share extension to allow users to share
/// IRCTC emails to the app, or reads from the Mail app via platform channel.
///
/// IRCTC sends booking confirmations to the registered email with subject
/// patterns like "E-Ticket Booking" or "IRCTC E-Ticket".
class EmailService {
  static const _channel = MethodChannel('com.travelcompanion/email');

  /// IRCTC email subject patterns to look for
  static const List<String> irctcSubjectPatterns = [
    'E-Ticket',
    'IRCTC',
    'E-ticket Booking',
    'Booked Ticket',
    'PNR',
  ];

  /// IRCTC email sender patterns
  static const List<String> irctcSenders = [
    'irctc.co.in',
    'irctc.com',
    'indianrailways.gov.in',
  ];

  /// Attempt to read IRCTC emails from the device mail app.
  /// Returns parsed email bodies that match IRCTC patterns.
  static Future<List<Map<String, dynamic>>> readIrctcEmails() async {
    try {
      final List<dynamic> emails = await _channel.invokeMethod(
        'getIrctcEmails',
        {
          'subjectPatterns': irctcSubjectPatterns,
          'senderPatterns': irctcSenders,
        },
      );

      return emails.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return {
          'subject': map['subject'] as String? ?? '',
          'body': map['body'] as String? ?? '',
          'sender': map['sender'] as String? ?? '',
          'date': map['date'] as int? ?? 0,
        };
      }).toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      // Platform channel not implemented
      return [];
    }
  }

  /// Parse IRCTC email body to extract ticket details.
  /// IRCTC emails contain HTML with tables — extract plain text fields.
  static Map<String, String?> parseIrctcEmail(String emailBody) {
    final fields = <String, String?>{};

    // PNR
    final pnrMatch = RegExp(r'PNR\s*[:\-]?\s*(\d{10})').firstMatch(emailBody);
    fields['pnr'] = pnrMatch?.group(1);

    // Train
    final trainMatch = RegExp(r'Train\s*(?:No\.?|Number)?\s*[:\-]?\s*(\d{5})\s*[-/]?\s*([A-Za-z\s]+?)(?:\s*<|\s*\n|\s*,)')
        .firstMatch(emailBody);
    fields['trainNumber'] = trainMatch?.group(1);
    fields['trainName'] = trainMatch?.group(2)?.trim();

    // Date
    final dateMatch = RegExp(r'Date\s*(?:of\s*Journey)?\s*[:\-]?\s*(\d{1,2}[-/]\w{3}[-/]\d{4})')
        .firstMatch(emailBody);
    fields['date'] = dateMatch?.group(1);

    // Stations
    final fromMatch = RegExp(r'(?:From|Boarding)\s*[:\-]?\s*([A-Za-z\s]+?)(?:\s*\(([A-Z]{2,5})\)|\s*<|\s*\n)')
        .firstMatch(emailBody);
    fields['fromStation'] = fromMatch?.group(2) ?? fromMatch?.group(1)?.trim();

    final toMatch = RegExp(r'(?:To|Destination)\s*[:\-]?\s*([A-Za-z\s]+?)(?:\s*\(([A-Z]{2,5})\)|\s*<|\s*\n)')
        .firstMatch(emailBody);
    fields['toStation'] = toMatch?.group(2) ?? toMatch?.group(1)?.trim();

    // Class
    final classMatch = RegExp(r'Class\s*[:\-]?\s*(SL|1A|2A|3A|CC|EC|2S|FC|3E)')
        .firstMatch(emailBody);
    fields['class'] = classMatch?.group(1);

    return fields;
  }
}
