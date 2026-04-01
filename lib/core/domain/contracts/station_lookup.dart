import 'package:travel_companion/data/models/station.dart';

abstract class StationLookup {
  Future<Station?> getByCode(String code);
}
