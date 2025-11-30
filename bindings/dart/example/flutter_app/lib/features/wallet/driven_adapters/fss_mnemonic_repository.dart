import 'package:flutter_app/features/wallet/application/ports/mnemonic_repository_port.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Adapter implementing MnemonicRepositoryPort using FlutterSecureStorage
class FssMnemonicRepository implements MnemonicRepositoryPort {
  final FlutterSecureStorage _storage;

  static const String _keyPrefix = 'mnemonic_';

  FssMnemonicRepository(this._storage);

  String _buildKey(String fingerprint) => '$_keyPrefix$fingerprint';

  @override
  Future<String> generateMnemonic() {
    // For simplicity, using a fixed mnemonic here; replace with real random
    //  generation in production code
    final mnemonic =
        'often cigar lens release accuse next truck license sausage tool rough parent';
    return Future.value(mnemonic);
  }

  @override
  Future<void> storeMnemonic({
    required String fingerprint,
    required String mnemonic,
  }) async {
    await _storage.write(key: _buildKey(fingerprint), value: mnemonic);
  }

  @override
  Future<String?> getMnemonic(String fingerprint) async {
    return await _storage.read(key: _buildKey(fingerprint));
  }

  @override
  Future<void> deleteMnemonic(String fingerprint) async {
    await _storage.delete(key: _buildKey(fingerprint));
  }

  @override
  Future<bool> hasMnemonic(String fingerprint) async {
    final mnemonic = await getMnemonic(fingerprint);
    return mnemonic != null;
  }
}
