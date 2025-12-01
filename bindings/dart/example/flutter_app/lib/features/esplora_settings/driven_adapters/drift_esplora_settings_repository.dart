import 'package:drift/drift.dart';
import 'package:flutter_app/core/frameworks/drift/app_database.dart';
import 'package:flutter_app/features/esplora_settings/application/ports/esplora_settings_repository.dart';
import 'package:flutter_app/features/esplora_settings/domain/entitites/esplora_endpoint_entity.dart';

extension EsploraEndpointMapper on EsploraEndpoint {
  EsploraEndpointEntity toDomainEntity() {
    return EsploraEndpointEntity(
      id: id,
      baseUrl: baseUrl,
      label: label,
      network: network,
      priority: priority,
    );
  }
}

class DriftEsploraSettingsRepository implements EsploraSettingsRepository {
  final AppDatabase _database;

  DriftEsploraSettingsRepository(this._database);

  @override
  Future<EsploraEndpointEntity> createEsploraEndpoint({
    required String baseUrl,
    String? label,
    required String network,
    int? priority,
  }) async {
    final insertedRow = await _database
        .into(_database.esploraEndpoints)
        .insertReturning(
          EsploraEndpointsCompanion.insert(
            baseUrl: baseUrl,
            label: Value(label),
            network: network,
            priority: priority == null ? const Value.absent() : Value(priority),
          ),
        );

    return insertedRow.toDomainEntity();
  }

  @override
  Future<EsploraEndpointEntity?> getEsploraEndpointByNetwork(
    String network,
  ) async {
    // Get the endpoint with highest priority for this network
    final query = _database.select(_database.esploraEndpoints)
      ..where((tbl) => tbl.network.equals(network))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.priority, mode: OrderingMode.desc),
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.toDomainEntity();
  }

  @override
  Future<List<EsploraEndpointEntity>> getEsploraEndpoints() async {
    // Get all endpoints ordered by priority (highest first)
    final query = _database.select(_database.esploraEndpoints)
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.priority, mode: OrderingMode.desc),
      ]);

    final results = await query.get();
    return results.map((row) => row.toDomainEntity()).toList();
  }

  @override
  Future<void> updateEsploraEndpoint(EsploraEndpointEntity endpoint) async {
    await (_database.update(
      _database.esploraEndpoints,
    )..where((tbl) => tbl.id.equals(endpoint.id))).write(
      EsploraEndpointsCompanion(
        baseUrl: Value(endpoint.baseUrl),
        label: Value(endpoint.label),
        network: Value(endpoint.network),
        priority: Value(endpoint.priority),
      ),
    );
  }

  @override
  Future<void> removeEsploraEndpoint(EsploraEndpointEntity endpoint) async {
    await (_database.delete(
      _database.esploraEndpoints,
    )..where((tbl) => tbl.id.equals(endpoint.id))).go();
  }
}
