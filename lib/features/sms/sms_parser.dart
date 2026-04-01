import 'package:travel_companion/core/constants/app_constants.dart';

class ParsedTicket {
  final String? pnr;
  final String? trainNumber;
  final String? trainName;
  final DateTime? journeyDate;
  final String? boardingStation;
  final String? destinationStation;
  final String? travelClass;
  final String? seatBerth;
  final int? passengerCount;

  const ParsedTicket({
    this.pnr,
    this.trainNumber,
    this.trainName,
    this.journeyDate,
    this.boardingStation,
    this.destinationStation,
    this.travelClass,
    this.seatBerth,
    this.passengerCount,
  });

  bool get isValid =>
      pnr != null &&
      trainNumber != null &&
      journeyDate != null &&
      boardingStation != null &&
      destinationStation != null;
}

class SmsParser {
  /// Parses an IRCTC booking confirmation SMS and extracts ticket details.
  ///
  /// Typical IRCTC SMS formats:
  /// "PNR: 1234567890, Train: 12345-RAJDHANI EXP, DOJ: 15-03-2026,
  ///  From: NEW DELHI(NDLS), To: MUMBAI CENTRAL(BCT), Class: 3A,
  ///  Passengers: 1, Fare: Rs.1500"
  ///
  /// "IRCTC Booking Confirmed. PNR 2345678901.
  ///  Train 22222 CSMT RAJDHANI. Date 20-Mar-2026.
  ///  NEW DELHI to MUMBAI CENTRAL. SL Class. Berth: S5/32/SU"
  ParsedTicket parse(String smsBody) {
    final upperBody = smsBody.toUpperCase();

    return ParsedTicket(
      pnr: _extractPnr(upperBody),
      trainNumber: _extractTrainNumber(upperBody),
      trainName: _extractTrainName(smsBody),
      journeyDate: _extractDate(smsBody),
      boardingStation: _extractBoardingStation(smsBody),
      destinationStation: _extractDestinationStation(smsBody),
      travelClass: _extractClass(upperBody),
      seatBerth: _extractBerth(smsBody),
      passengerCount: _extractPassengerCount(upperBody),
    );
  }

  String? _extractPnr(String text) {
    // PNR is always a 10-digit number
    final patterns = [
      RegExp(r'PNR\s*[:\-]?\s*(\d{10})'),
      RegExp(r'PNR\s+NO\s*[:\-]?\s*(\d{10})'),
      RegExp(r'PNR\s+NUMBER\s*[:\-]?\s*(\d{10})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  String? _extractTrainNumber(String text) {
    final patterns = [
      RegExp(r'TRAIN\s*[:\-]?\s*(\d{5})'),
      RegExp(r'TRAIN\s+NO\s*[:\-]?\s*(\d{5})'),
      RegExp(r'TRN\s*[:\-]?\s*(\d{5})'),
      RegExp(r'(\d{5})\s*[-/]'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  String? _extractTrainName(String text) {
    final patterns = [
      RegExp(
        r'\d{5}\s*[-/]\s*([A-Za-z\s]+?)(?:\s*[,.]|\s+DOJ|\s+Date|\s+on)',
        caseSensitive: false,
      ),
      RegExp(
        r'TRAIN\s*:\s*\d{5}\s*[-/]?\s*([A-Za-z\s]+?)(?:\s*[,.])',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1)?.trim();
    }
    return null;
  }

  DateTime? _extractDate(String text) {
    // Try DD-Mon-YYYY first (e.g. 15-Mar-2026)
    final monthPattern = RegExp(
      r'(\d{1,2})\s*[-/]\s*([A-Za-z]{3})\s*[-/]\s*(\d{4})',
    );
    final monthMatch = monthPattern.firstMatch(text);
    if (monthMatch != null) {
      final day = int.parse(monthMatch.group(1)!);
      final monthStr = monthMatch.group(2)!.toUpperCase();
      final year = int.parse(monthMatch.group(3)!);
      final month = _monthFromString(monthStr);
      if (month != null) return DateTime(year, month, day);
    }

    // Try DD-MM-YYYY / DD/MM/YYYY, optionally prefixed by DOJ:
    for (final pattern in [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'),
      RegExp(r'DOJ\s*[:\-]?\s*(\d{1,2})[/-](\d{1,2})[/-](\d{4})'),
    ]) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  int? _monthFromString(String month) {
    const months = {
      'JAN': 1,
      'FEB': 2,
      'MAR': 3,
      'APR': 4,
      'MAY': 5,
      'JUN': 6,
      'JUL': 7,
      'AUG': 8,
      'SEP': 9,
      'OCT': 10,
      'NOV': 11,
      'DEC': 12,
    };
    return months[month.toUpperCase()];
  }

  String? _extractBoardingStation(String text) {
    final patterns = [
      RegExp(
        r'FROM\s*[:\-]?\s*([A-Za-z\s]+?)\s*\(([A-Z]{2,5})\)',
        caseSensitive: false,
      ),
      RegExp(r'FROM\s*[:\-]?\s*([A-Za-z\s]+?)\s+TO\b', caseSensitive: false),
      RegExp(
        r'(?:from|depart)\s+([A-Za-z\s]+?)\s+(?:to|for)\b',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        if (match.groupCount >= 2 && match.group(2) != null) {
          return match.group(2)!.trim();
        }
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  String? _extractDestinationStation(String text) {
    final patterns = [
      RegExp(
        r'TO\s*[:\-]?\s*([A-Za-z\s]+?)\s*\(([A-Z]{2,5})\)',
        caseSensitive: false,
      ),
      RegExp(
        r'\bTO\s*[:\-]?\s*([A-Za-z\s]+?)(?:\s*[,.]|\s+CLASS|\s+SL|\s+\dA)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        if (match.groupCount >= 2 && match.group(2) != null) {
          return match.group(2)!.trim();
        }
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  String? _extractClass(String text) {
    final pattern = RegExp(
      r'CLASS\s*[:\-]?\s*(SL|1A|2A|3A|CC|EC|2S|FC|3E)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match != null) return match.group(1)!.toUpperCase();

    final standaloneMatch = RegExp(
      r'\b(SL|1A|2A|3A|CC|EC|2S|FC|3E)\s+CLASS',
      caseSensitive: false,
    ).firstMatch(text);
    return standaloneMatch?.group(1)?.toUpperCase();
  }

  String? _extractBerth(String text) {
    final match = RegExp(
      r'BERTH\s*[:\-]?\s*([A-Z0-9/]+)',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1)?.trim();
  }

  int? _extractPassengerCount(String text) {
    final match = RegExp(r'PASSENGER[S]?\s*[:\-]?\s*(\d+)').firstMatch(text);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  /// Check if an SMS is from IRCTC
  bool isIrctcSms(String sender) {
    final upperSender = sender.toUpperCase();
    return AppConstants.irctcSenderIds.any((id) => upperSender.contains(id));
  }

  /// Check if SMS is a booking confirmation (not cancellation, refund, etc.)
  bool isBookingConfirmation(String body) {
    final upper = body.toUpperCase();
    return (upper.contains('BOOKING') && upper.contains('CONFIRM')) ||
        (upper.contains('PNR') && upper.contains('TRAIN')) ||
        upper.contains('TICKET BOOKED');
  }
}
