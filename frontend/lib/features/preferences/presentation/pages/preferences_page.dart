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
  final _formKey = GlobalKey<FormState>();
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
        _minBudgetController.text = state.currentPreference!.minBudget!.toStringAsFixed(0);
      }
      if (state.currentPreference!.maxBudget != null && _maxBudgetController.text.isEmpty) {
        _maxBudgetController.text = state.currentPreference!.maxBudget!.toStringAsFixed(0);
      }
      if (state.currentPreference!.hasPet != null) {
        _hasPet = state.currentPreference!.hasPet!;
      }
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
          disabledHint: const Text('Vui lòng chọn mục ở trên trước'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sở thích tìm trọ'),
        centerTitle: true,
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
              SnackBar(
                content: Text(state.errorMessage ?? 'Lỗi'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == PreferencesStatus.loading || state.status == PreferencesStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          _populateInitialData(state);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.currentPreference?.preferredArea != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Khu vực hiện tại: ${state.currentPreference!.preferredArea}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Khu vực mong muốn',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown<Province>(
                    label: 'Tỉnh/Thành phố',
                    value: state.selectedProvince,
                    items: state.provinces.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) context.read<PreferencesCubit>().onProvinceChanged(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown<District>(
                    label: 'Quận/Huyện',
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
                  _buildDropdown<Ward>(
                    label: 'Phường/Xã',
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
                  const SizedBox(height: 32),
                  Text(
                    'Ngân sách dự kiến',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ngân sách tối thiểu (VNĐ)',
                      prefixIcon: const Icon(Icons.attach_money),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ngân sách tối đa (VNĐ)',
                      prefixIcon: const Icon(Icons.money_off),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SwitchListTile(
                      title: const Text('Có mang theo thú cưng', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Tick chọn nếu bạn dự định nuôi chó mèo'),
                      secondary: const Icon(Icons.pets),
                      value: _hasPet,
                      onChanged: (val) {
                        setState(() {
                          _hasPet = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFFD85D15),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: state.status == PreferencesStatus.updating
                          ? null
                          : () {
                              final min = double.tryParse(_minBudgetController.text);
                              final max = double.tryParse(_maxBudgetController.text);
                              context.read<PreferencesCubit>().updatePreferences(min, max, _hasPet);
                            },
                      child: state.status == PreferencesStatus.updating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Lưu thông tin',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
