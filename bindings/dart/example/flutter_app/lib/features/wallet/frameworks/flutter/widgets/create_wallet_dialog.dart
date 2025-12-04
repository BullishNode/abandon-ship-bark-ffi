import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/color_palette.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_bloc.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateWalletDialog extends StatefulWidget {
  const CreateWalletDialog({super.key});

  @override
  State<CreateWalletDialog> createState() => _CreateWalletDialogState();
}

class _CreateWalletDialogState extends State<CreateWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aspController = TextEditingController(
    text: 'https://ark.signet.2nd.dev',
  );
  final _descriptionController = TextEditingController();

  // Advanced settings with defaults
  final _vtxoRefreshExpiryThresholdController = TextEditingController();
  final _vtxoExitMarginController = TextEditingController();
  final _htlcRecvClaimDeltaController = TextEditingController();

  bool _showAdvanced = false;

  @override
  void dispose() {
    _nameController.dispose();
    _aspController.dispose();
    _descriptionController.dispose();
    _vtxoRefreshExpiryThresholdController.dispose();
    _vtxoExitMarginController.dispose();
    _htlcRecvClaimDeltaController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    if (_formKey.currentState!.validate()) {
      context.read<WalletBloc>().add(
        CreateWallet(
          name: _nameController.text,
          asp: _aspController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          vtxoRefreshExpiryThreshold: _parseInt(
            _vtxoRefreshExpiryThresholdController.text,
          ),
          vtxoExitMargin: _parseInt(_vtxoExitMarginController.text),
          htlcRecvClaimDelta: _parseInt(_htlcRecvClaimDeltaController.text),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  int? _parseInt(String value) {
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.gray900 : AppColors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Wallet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Wallet Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Wallet Name',
                    hintText: 'My Wallet',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.gray800 : AppColors.gray100,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a wallet name';
                    }
                    if (value.length > 100) {
                      return 'Name must be less than 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Wallet Type (only Bark for now)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray800 : AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wallet, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Type: Bark',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ASP URL Field
                TextFormField(
                  controller: _aspController,
                  decoration: InputDecoration(
                    labelText: 'ASP URL',
                    hintText: 'https://ark.signet.2nd.dev',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.gray800 : AppColors.gray100,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an ASP URL';
                    }
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return 'URL must start with http:// or https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description (optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Personal wallet',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.gray800 : AppColors.gray100,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Advanced Settings Toggle
                InkWell(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Advanced Settings',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showAdvanced) ...[
                  const SizedBox(height: 16),
                  _buildAdvancedField(
                    controller: _vtxoRefreshExpiryThresholdController,
                    label: 'VTXO Refresh Expiry Threshold (seconds)',
                    hint: 'Leave empty for server default',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildAdvancedField(
                    controller: _vtxoExitMarginController,
                    label: 'VTXO Exit Margin (seconds)',
                    hint: 'Leave empty for server default',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildAdvancedField(
                    controller: _htlcRecvClaimDeltaController,
                    label: 'HTLC Receive Claim Delta (blocks)',
                    hint: 'Leave empty for server default',
                    isDark: isDark,
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleCreate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: isDark
                            ? AppColors.white
                            : AppColors.black,
                        foregroundColor: isDark
                            ? AppColors.black
                            : AppColors.white,
                      ),
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? AppColors.gray800 : AppColors.gray100,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final parsed = int.tryParse(value);
          if (parsed == null) {
            return 'Must be a valid number';
          }
        }
        return null;
      },
    );
  }
}
