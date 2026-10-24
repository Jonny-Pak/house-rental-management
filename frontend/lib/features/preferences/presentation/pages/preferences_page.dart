import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/preference_remote_data_source.dart';
import '../../data/models/personal_interests.dart';
import '../../data/repositories/preference_repository.dart';
import '../cubit/preferences_cubit.dart';
import '../cubit/preferences_state.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key, this.repository, this.onSaved});
  final PreferenceRepository? repository;
  final ValueChanged<List<String>>? onSaved;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PreferencesCubit(
      repository ??
          PreferenceRepositoryImpl(PreferenceRemoteDataSourceImpl(ApiClient())),
    )..loadInitialData(),
    child: PreferencesView(onSaved: onSaved),
  );
}

class PreferencesView extends StatelessWidget {
  const PreferencesView({super.key, this.onSaved});
  final ValueChanged<List<String>>? onSaved;

  IconData _icon(String code) {
    switch (code) {
      case 'CAT_LOVER':
        return Symbols.pets;
      case 'DOG_LOVER':
        return Symbols.cruelty_free;
      case 'PLANTS':
        return Symbols.potted_plant;
      case 'QUIET':
        return Symbols.volume_off;
      case 'TIDY':
        return Symbols.cleaning_services;
      case 'STUDY':
        return Symbols.school;
      case 'EARLY_BIRD':
        return Symbols.wb_sunny;
      case 'NIGHT_OWL':
        return Symbols.nights_stay;
      case 'NON_SMOKER':
        return Symbols.smoke_free;
      case 'SOCIABLE':
        return Symbols.groups;
      case 'MUSIC':
        return Symbols.headphones;
      case 'MOVIES':
        return Symbols.movie;
      case 'READING':
        return Symbols.menu_book;
      case 'GAMING':
        return Symbols.sports_esports;
      case 'COOKING':
        return Symbols.skillet;
      case 'SPORTS':
        return Symbols.fitness_center;
      case 'TRAVEL':
        return Symbols.flight;
      default:
        return Symbols.coffee;
    }
  }

  Widget _group(
    BuildContext context,
    PreferencesState state,
    String title,
    List<String> codes,
  ) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFEEDFD1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF38291F),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 9,
            runSpacing: 10,
            children: [
              for (final code in codes)
                FilterChip(
                  key: ValueKey('interest-$code'),
                  selected: state.interests.contains(code),
                  showCheckmark: false,
                  avatar: Icon(
                    _icon(code),
                    size: 18,
                    color: state.interests.contains(code)
                        ? const Color(0xFFAF541E)
                        : const Color(0xFFAD8A68),
                  ),
                  label: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - 74,
                    ),
                    child: Text(
                      personalInterestLabels[code]!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: state.interests.contains(code)
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: const Color(0xFF573B28),
                      ),
                    ),
                  ),
                  selectedColor: const Color(0xFFFFE4C7),
                  backgroundColor: const Color(0xFFFCFAF7),
                  side: BorderSide(
                    color: state.interests.contains(code)
                        ? const Color(0xFFDCA778)
                        : const Color(0xFFEEDFD1),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected:
                      state.status == PreferencesStatus.updating ||
                          (state.interests.length >= 5 &&
                              !state.interests.contains(code))
                      ? null
                      : (_) => context.read<PreferencesCubit>().toggleInterest(
                          code,
                        ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8F5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAF8F5),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Sở thích của tôi',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFF38291F),
        ),
      ),
    ),
    body: AppContent(
      maxWidth: AppLayout.formWidth,
      child: BlocConsumer<PreferencesCubit, PreferencesState>(
        listener: (context, state) {
          if (state.status == PreferencesStatus.updateSuccess) {
            onSaved?.call(List<String>.of(state.interests));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã lưu sở thích của bạn.')),
            );
            Navigator.of(context).maybePop(List<String>.of(state.interests));
          } else if (state.status == PreferencesStatus.error &&
              state.currentPreference != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Không lưu được sở thích.'),
                backgroundColor: const Color(0xFFAE5141),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == PreferencesStatus.initial ||
              state.status == PreferencesStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD76B28)),
            );
          }
          if (state.currentPreference == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Symbols.cloud_off,
                      color: Color(0xFFAD8A68),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Không tải được sở thích.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<PreferencesCubit>().loadInitialData(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFEBD6), Color(0xFFFFFAF4)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Symbols.interests,
                            size: 36,
                            color: Color(0xFFD76B28),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Một chút về bạn',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF38291F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Chọn những sở thích và thói quen thể hiện con người bạn. Bạn có thể chọn tối đa 5 mục và thay đổi bất cứ lúc nào.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: Color(0xFF8A7464),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Đã chọn ${state.interests.length}/5 sở thích',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFAF541E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _group(context, state, 'Thú cưng & thiên nhiên', const [
                      'CAT_LOVER',
                      'DOG_LOVER',
                      'PLANTS',
                    ]),
                    const SizedBox(height: 16),
                    _group(context, state, 'Giải trí & đam mê', const [
                      'MUSIC',
                      'MOVIES',
                      'READING',
                      'GAMING',
                      'COOKING',
                      'SPORTS',
                      'TRAVEL',
                      'COFFEE',
                    ]),
                    const SizedBox(height: 16),
                    _group(context, state, 'Thói quen sống', const [
                      'QUIET',
                      'TIDY',
                      'STUDY',
                      'EARLY_BIRD',
                      'NIGHT_OWL',
                      'NON_SMOKER',
                      'SOCIABLE',
                    ]),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEDFD1))),
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: FilledButton(
                    onPressed: state.status == PreferencesStatus.updating
                        ? null
                        : () => context
                              .read<PreferencesCubit>()
                              .updatePreferences(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD76B28),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      state.status == PreferencesStatus.updating
                          ? 'Đang lưu…'
                          : 'Lưu sở thích',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
