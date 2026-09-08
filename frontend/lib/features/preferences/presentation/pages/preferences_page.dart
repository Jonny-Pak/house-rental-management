import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/area_remote_data_source.dart';
import '../../data/datasources/preference_remote_data_source.dart';
import '../../data/models/area_models.dart';
import '../../data/repositories/area_repository.dart';
import '../../data/repositories/preference_repository.dart';
import '../cubit/preferences_cubit.dart';
import '../cubit/preferences_state.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final apiClient = ApiClient();
        final areaRepo = AreaRepositoryImpl(AreaRemoteDataSourceImpl(apiClient));
        final prefRepo = PreferenceRepositoryImpl(PreferenceRemoteDataSourceImpl(apiClient));
        return PreferencesCubit(areaRepo, prefRepo)..loadInitialData();
      },
      child: const PreferencesView(),
    );
  }
}

class PreferencesView extends StatefulWidget {
  const PreferencesView({super.key});

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  bool _hasPet = false;

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  void _populateInitialData(PreferencesState state) {
    if (state.currentPreference != null) {
      if (state.currentPreference!.minBudget != null && _minBudgetController.text.isEmpty) {
        _minBudgetController.text = state.currentPreference!.minBudget!.toString();
      }
      if (state.currentPreference!.maxBudget != null && _maxBudgetController.text.isEmpty) {
        _maxBudgetController.text = state.currentPreference!.maxBudget!.toString();
      }
      if (state.currentPreference!.hasPet != null) {
        _hasPet = state.currentPreference!.hasPet!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sở thích tìm trọ'),
      ),
      body: BlocConsumer<PreferencesCubit, PreferencesState>(
        listener: (context, state) {
          if (state.status == PreferencesStatus.updateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật thành công!')),
            );
            Navigator.pop(context);
          } else if (state.status == PreferencesStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Lỗi')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == PreferencesStatus.loading || state.status == PreferencesStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          _populateInitialData(state);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.currentPreference?.preferredArea != null) ...[
                  Text(
                    'Khu vực hiện tại: ${state.currentPreference!.preferredArea}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButton<Province>(
                  isExpanded: true,
                  hint: const Text('Chọn Tỉnh/Thành phố'),
                  value: state.selectedProvince,
                  items: state.provinces.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.name));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) context.read<PreferencesCubit>().onProvinceChanged(val);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButton<District>(
                  isExpanded: true,
                  hint: const Text('Chọn Quận/Huyện'),
                  value: state.selectedDistrict,
                  items: state.districts.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d.name));
                  }).toList(),
                  onChanged: state.selectedProvince == null
                      ? null
                      : (val) {
                          if (val != null) context.read<PreferencesCubit>().onDistrictChanged(val);
                        },
                ),
                const SizedBox(height: 16),
                DropdownButton<Ward>(
                  isExpanded: true,
                  hint: const Text('Chọn Phường/Xã'),
                  value: state.selectedWard,
                  items: state.wards.map((w) {
                    return DropdownMenuItem(value: w, child: Text(w.name));
                  }).toList(),
                  onChanged: state.selectedDistrict == null
                      ? null
                      : (val) {
                          if (val != null) context.read<PreferencesCubit>().onWardChanged(val);
                        },
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _minBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ngân sách tối thiểu (VNĐ)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _maxBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ngân sách tối đa (VNĐ)'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Có mang theo thú cưng'),
                  value: _hasPet,
                  onChanged: (val) {
                    setState(() {
                      _hasPet = val;
                    });
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: state.status == PreferencesStatus.updating
                        ? null
                        : () {
                            final min = double.tryParse(_minBudgetController.text);
                            final max = double.tryParse(_maxBudgetController.text);
                            context.read<PreferencesCubit>().updatePreferences(min, max, _hasPet);
                          },
                    child: state.status == PreferencesStatus.updating
                        ? const CircularProgressIndicator()
                        : const Text('Lưu thông tin'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
