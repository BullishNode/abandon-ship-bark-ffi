import 'package:dartz/dartz.dart';
import 'package:flutter_app/core/application/error/failures.dart';
import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/wallet/application/dtos/wallet_backup_dto.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';
import 'package:flutter_app/features/wallet/domain/value_objects/wallet_backup_vo.dart';

/// Query for getting wallet backup
class GetWalletBackupQuery {
  final int walletId;

  const GetWalletBackupQuery({required this.walletId});
}

/// Response containing wallet backup DTO
class WalletBackupResponse {
  final WalletBackupDto backup;

  const WalletBackupResponse({required this.backup});
}

/// Use case for getting wallet backup data
class GetWalletBackup
    implements UseCase<WalletBackupResponse, GetWalletBackupQuery> {
  final WalletService _walletService;

  GetWalletBackup(this._walletService);

  @override
  Future<Either<Failure, WalletBackupResponse>> call(
    GetWalletBackupQuery query,
  ) async {
    final result = await _walletService.getWalletBackup(query.walletId);

    return result.map((backupVO) {
      // Map VO to DTO
      final WalletBackupDto dto;
      if (backupVO is BarkWalletBackupVO) {
        dto = BarkWalletBackupDto(
          mnemonic: backupVO.mnemonic,
          fingerprint: backupVO.fingerprint,
        );
      } else {
        throw UnimplementedError('Unsupported wallet backup type');
      }
      return WalletBackupResponse(backup: dto);
    });
  }
}
