import 'package:flutter/material.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/color_palette.dart';
import 'package:flutter_app/core/frameworks/get_it/injection_container.dart';
import 'package:flutter_app/features/settings/driving_adapters/presenters/bloc/settings_bloc.dart';
import 'package:flutter_app/features/settings/driving_adapters/presenters/bloc/settings_event.dart';
import 'package:flutter_app/features/settings/driving_adapters/presenters/bloc/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsBloc>()..add(const LoadSettings()),
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SettingsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SettingsBloc>().add(const LoadSettings());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is SettingsLoaded) {
          return ListView(
            children: [
              // Network section
              _SectionHeader(title: 'Network', isDark: isDark),
              _NetworkTile(
                currentNetwork: state.currentNetwork,
                availableNetworks: state.availableNetworks,
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // Esplora section
              _SectionHeader(title: 'Esplora', isDark: isDark),
              _EsploraEndpointsTile(isDark: isDark),

              const SizedBox(height: 24),

              // Display section
              //_SectionHeader(title: 'Display', isDark: isDark),
              //_HideBalanceTile(hideBalance: state.hideBalance, isDark: isDark),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.gray400 : AppColors.gray600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  final String currentNetwork;
  final List<String> availableNetworks;
  final bool isDark;

  const _NetworkTile({
    required this.currentNetwork,
    required this.availableNetworks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark900 : AppColors.white,
        border: Border.all(
          color: isDark ? AppColors.gray800 : AppColors.gray200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          'Bitcoin Network',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        subtitle: Text(
          currentNetwork.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.gray400 : AppColors.gray600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? AppColors.gray600 : AppColors.gray400,
        ),
        onTap: () => _showNetworkPicker(context),
      ),
    );
  }

  void _showNetworkPicker(BuildContext context) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Network',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Only Signet is supported at this time',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ...availableNetworks.map((network) {
                  final isSelected = network == currentNetwork;
                  final isSignet = network.toLowerCase() == 'signet';
                  return ListTile(
                    enabled: isSignet,
                    title: Text(
                      network.toUpperCase(),
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSignet
                            ? (isDark ? AppColors.white : AppColors.black)
                            : (isDark ? AppColors.gray700 : AppColors.gray400),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.bitcoin)
                        : null,
                    onTap: isSignet
                        ? () {
                            context.read<SettingsBloc>().add(
                              ChangeNetwork(network),
                            );
                            Navigator.pop(sheetContext);
                          }
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EsploraEndpointsTile extends StatelessWidget {
  final bool isDark;

  const _EsploraEndpointsTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark900 : AppColors.white,
        border: Border.all(
          color: isDark ? AppColors.gray800 : AppColors.gray200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Row(
          children: [
            Text(
              'Esplora Endpoints',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.gray800 : AppColors.gray200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Coming soon',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Manage your own Esplora server endpoints',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.gray400 : AppColors.gray600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? AppColors.gray600 : AppColors.gray400,
        ),
        enabled: false,
        onTap: null,
      ),
    );
  }
}

class _HideBalanceTile extends StatelessWidget {
  final bool hideBalance;
  final bool isDark;

  const _HideBalanceTile({required this.hideBalance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark900 : AppColors.white,
        border: Border.all(
          color: isDark ? AppColors.gray800 : AppColors.gray200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          'Hide Balance',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        subtitle: Text(
          'Hide wallet balance on main screen',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.gray400 : AppColors.gray600,
          ),
        ),
        value: hideBalance,
        activeThumbColor: AppColors.bitcoin,
        onChanged: (value) {
          context.read<SettingsBloc>().add(const ToggleHideBalance());
        },
      ),
    );
  }
}
