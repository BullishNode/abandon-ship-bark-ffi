import 'package:flutter_app/features/esplora_settings/domain/entitites/esplora_endpoint_entity.dart';

abstract class EsploraSettingsRepository {
  Future<void> createEsploraEndpoint({
    required String baseUrl,
    String? label,
    required String network,
  });
  Future<List<EsploraEndpointEntity>> getEsploraEndpoints();
  Future<EsploraEndpointEntity?> getEsploraEndpointByNetwork(String network);
  Future<void> updateEsploraEndpoint(EsploraEndpointEntity endpoint);
  Future<void> removeEsploraEndpoint(EsploraEndpointEntity endpoint);
}
