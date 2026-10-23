import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/layout/app_layout.dart';
import '../cubit/create_listing_cubit.dart';
import '../cubit/create_listing_state.dart';
import '../widgets/roommate_form.dart';

const _accent = Color(0xFFD76B28);
const _ink = Color(0xFF38291F);
const _muted = Color(0xFF8A7464);
const _border = Color(0xFFEEDFD1);

class ListingDetailsStep extends StatelessWidget {
  const ListingDetailsStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });
  final VoidCallback onNext, onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8F5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAF8F5),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: onBack,
        icon: const Icon(Symbols.arrow_back, color: _ink, size: 23),
      ),
      title: const Text(
        'Chi tiết bất động sản',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
    ),
    body: AppContent(
      maxWidth: AppLayout.formWidth,
      child: BlocBuilder<CreateListingCubit, CreateListingState>(
        builder: (context, state) {
          final cubit = context.read<CreateListingCubit>();
          final isHouse = state.propertyType == 'WHOLE_HOUSE';
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    const Text(
                      'BƯỚC 03 / 04  ·  THÔNG TIN CHI TIẾT',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không gian có gì đặc biệt?',
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bổ sung thông tin để người thuê dễ dàng tìm được nơi phù hợp.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isHouse) ...[
                      _DetailSection(
                        title: 'Không gian & kết cấu',
                        icon: Symbols.home_work,
                        children: [
                          _DropdownField(
                            label: 'Loại hình nhà ở *',
                            hint: 'Chọn loại hình',
                            value: state.houseType,
                            options: const {
                              'MAT_PHO': 'Nhà mặt phố',
                              'NGO_HEM': 'Nhà ngõ hẻm',
                              'BIET_THU': 'Biệt thự',
                              'LIEN_KE': 'Nhà liền kề',
                            },
                            onChanged: cubit.updateHouseType,
                          ),
                          const SizedBox(height: 20),
                          _FieldPair(
                            first: _CounterField(
                              label: 'Phòng ngủ *',
                              value: state.bedrooms ?? 0,
                              onChanged: cubit.updateBedrooms,
                            ),
                            second: _CounterField(
                              label: 'Phòng tắm *',
                              value: state.bathrooms ?? 0,
                              onChanged: cubit.updateBathrooms,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _FieldPair(
                            first: _CounterField(
                              label: 'Tổng số tầng',
                              value: state.totalFloors ?? 0,
                              onChanged: cubit.updateTotalFloors,
                            ),
                            second: _DropdownField(
                              label: 'Hướng cửa',
                              hint: 'Chọn hướng',
                              value: state.doorDirection,
                              options: const {
                                'EAST': 'Đông',
                                'WEST': 'Tây',
                                'SOUTH': 'Nam',
                                'NORTH': 'Bắc',
                                'SOUTHEAST': 'Đông Nam',
                                'NORTHEAST': 'Đông Bắc',
                                'SOUTHWEST': 'Tây Nam',
                                'NORTHWEST': 'Tây Bắc',
                              },
                              onChanged: cubit.updateDoorDirection,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (state.propertyType == 'SHARED_ROOM') ...[
                      _DetailSection(
                        title: 'Thông tin tìm người ở ghép',
                        icon: Symbols.group,
                        children: [
                          RoommateForm(
                            value: state.roommateInfo,
                            onChanged: cubit.updateRoommateInfo,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    _DetailSection(
                      title: isHouse
                          ? 'Pháp lý & nội thất'
                          : 'Nội thất phòng trọ',
                      icon: Symbols.fact_check,
                      children: [
                        if (isHouse) ...[
                          _DropdownField(
                            label: 'Giấy tờ pháp lý',
                            hint: 'Chọn loại giấy tờ',
                            value: state.legalDocuments,
                            options: const {
                              'PINK_BOOK': 'Sổ hồng',
                              'RED_BOOK': 'Sổ đỏ',
                              'SALE_CONTRACT': 'Hợp đồng mua bán',
                              'NONE': 'Chưa có',
                            },
                            onChanged: cubit.updateLegalDocuments,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _DropdownField(
                          label: 'Tình trạng nội thất *',
                          hint: 'Chọn tình trạng',
                          value: state.furnitureStatus,
                          options: const {
                            'FULL': 'Đầy đủ nội thất',
                            'BASIC': 'Nội thất cơ bản',
                            'EMPTY': 'Nhà trống',
                          },
                          onChanged: cubit.updateFurnitureStatus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '* Thông tin bắt buộc',
                      style: TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _border)),
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _canProceed(state) ? onNext : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF0EBE5),
                        disabledForegroundColor: const Color(0xFFAD9D8E),
                        minimumSize: const Size.fromHeight(52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Symbols.arrow_forward, size: 20),
                      iconAlignment: IconAlignment.end,
                      label: const Text(
                        'Tiếp tục',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
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

  bool _canProceed(CreateListingState state) {
    if (state.propertyType == 'WHOLE_HOUSE') {
      return state.houseType != null &&
          state.bedrooms != null &&
          state.bedrooms! > 0 &&
          state.bathrooms != null &&
          state.bathrooms! > 0 &&
          state.furnitureStatus != null;
    }
    if (state.propertyType == 'SHARED_ROOM' && !state.roommateInfo.isValid) {
      return false;
    }
    return state.furnitureStatus != null;
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: _accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        ...children,
      ],
    ),
  );
}

class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.first, required this.second});
  final Widget first, second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(14) > 20) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 20), second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 16),
          Expanded(child: second),
        ],
      );
    },
  );
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label, hint;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
      const SizedBox(height: 9),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAF7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            itemHeight: null,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            style: const TextStyle(fontSize: 14, height: 1.4, color: _ink),
            hint: Text(
              hint,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
            icon: const Icon(Symbols.expand_more, size: 22, color: _muted),
            items: [
              for (final entry in options.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(entry.value),
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
      const SizedBox(height: 9),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAF7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Giảm $label',
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Symbols.remove, size: 20),
              color: _muted,
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Tăng $label',
              onPressed: () => onChanged(value + 1),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFEBD9),
                foregroundColor: _accent,
              ),
              icon: const Icon(Symbols.add, size: 20),
            ),
          ],
        ),
      ),
    ],
  );
}
