import 'package:travel_companion/core/domain/contracts/station_lookup.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/repositories/station_repository.dart';

class StationRepositoryLookup implements StationLookup {
  const StationRepositoryLookup(this._repository);

  final StationRepository _repository;

  @override
  Future<Station?> getByCode(String code) {
    return _repository.getStationByCode(code);
  }
}
