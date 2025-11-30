import 'package:flutter_app/features/wallet/domain/entities/wallet_config.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_type_vo.dart';

/// General wallet entity (domain model)
/// Entities are compared by identity (id), not by value
class WalletEntity {
  final int _id;
  String _name;
  final WalletTypeVO _type;
  final String _network;
  final DateTime _createdAt;
  final DateTime _updatedAt;
  String? _description;
  final WalletConfig _config;

  WalletEntity({
    required int id,
    required String name,
    required WalletTypeVO type,
    required String network,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? description,
    required WalletConfig config,
  }) : _id = id,
       _name = name,
       _type = type,
       _network = network,
       _createdAt = createdAt,
       _updatedAt = updatedAt,
       _description = description,
       _config = config;

  int get id => _id;
  String get name => _name;
  WalletTypeVO get type => _type;
  String get network => _network;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;
  String? get description => _description;
  WalletConfig get config => _config;

  void updateName(String newName) {
    _name = newName;
  }

  void updateDescription(String? newDescription) {
    _description = newDescription;
  }

  /// Entities are equal if they have the same identity (id)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
