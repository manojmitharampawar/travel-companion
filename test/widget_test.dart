import 'package:flutter_test/flutter_test.dart';
import 'package:travel_companion/features/sms/sms_parser.dart';

void main() {
  group('SmsParser', () {
    late SmsParser parser;

    setUp(() {
      parser = SmsParser();
    });

    test('parses IRCTC booking SMS with PNR and train details', () {
      const sms =
          'PNR: 1234567890, Train: 12345-RAJDHANI EXP, DOJ: 15-03-2026, '
          'From: NEW DELHI(NDLS), To: MUMBAI CENTRAL(BCT), Class: 3A, '
          'Passengers: 1, Fare: Rs.1500';

      final result = parser.parse(sms);

      expect(result.pnr, '1234567890');
      expect(result.trainNumber, '12345');
      expect(result.journeyDate, DateTime(2026, 3, 15));
      expect(result.boardingStation, 'NDLS');
      expect(result.destinationStation, 'BCT');
      expect(result.travelClass, '3A');
    });

    test('detects IRCTC sender IDs', () {
      expect(parser.isIrctcSms('AX-IRCTCE'), isTrue);
      expect(parser.isIrctcSms('IRCTC'), isTrue);
      expect(parser.isIrctcSms('RANDOM-SENDER'), isFalse);
    });

    test('detects booking confirmation messages', () {
      expect(
        parser.isBookingConfirmation('IRCTC Booking Confirmed. PNR 1234567890'),
        isTrue,
      );
      expect(
        parser.isBookingConfirmation('Your ticket has been cancelled'),
        isFalse,
      );
    });
  });
}
