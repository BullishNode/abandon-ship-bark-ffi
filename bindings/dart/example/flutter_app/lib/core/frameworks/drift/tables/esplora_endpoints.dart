import 'package:drift/drift.dart';

class EsploraEndpoints extends Table {
  IntColumn get id => integer().autoIncrement()();

  // full base URL: "https://example.com/esplora"
  TextColumn get baseUrl => text()();

  // optional: for labeling in UI
  TextColumn get label => text().nullable()();

  /// Bitcoin network
  TextColumn get network => text()();

  /// Priority for selection (lower number = higher priority)
  IntColumn get priority => integer().withDefault(const Constant(0))();
}
