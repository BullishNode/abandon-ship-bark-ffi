import 'package:flutter_app/features/wallet/domain/value_objects/wallet_type_vo.dart';

/// General wallet entity
class WalletEntity {
  final int _id;
  String _name;
  final WalletTypeVO _type;
  final String _network;
  String? _description;
  final DateTime _createdAt;
  final DateTime _updatedAt;

  WalletEntity({
    required int id,
    required String name,
    required WalletTypeVO type,
    required String network,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : _id = id,
       _name = name,
       _type = type,
       _network = network,
       _description = description,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  int get id => _id;
  String get name => _name;
  WalletTypeVO get type => _type;
  String get network => _network;
  String? get description => _description;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;

  void updateName(String newName) {
    _name = newName;
  }

  void updateDescription(String? newDescription) {
    _description = newDescription;
  }
}
