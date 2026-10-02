import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/create_listing_cubit.dart';
import '../cubit/create_listing_state.dart';

const _kAccent = Color(0xFFD85D15);
const _kDark = Color(0xFF2C1D11);
const _kBackground = Color(0xFFFAF8F5);
const _kBorder = Color(0xFFE8DED1);

class ListingDetailsStep extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ListingDetailsStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kDark),
          onPressed: onBack,
        ),
        title: const Text(
          'Chi tiết bất động sản',
          style: TextStyle(color: _kDark, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: BlocBuilder<CreateListingCubit, CreateListingState>(
        builder: (context, state) {
          final cubit = context.read<CreateListingCubit>();
          final isHouse = state.propertyType == 'WHOLE_HOUSE';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (isHouse) ...[
                      // --- House Type ---
                      _buildSectionTitle('Loại hình nhà ở'),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: state.houseType,
                        hint: 'Chọn loại hình nhà ở',
                        items: const [
                          DropdownMenuItem(value: 'MAT_PHO', child: Text('Nhà mặt phố')),
                          DropdownMenuItem(value: 'NGO_HEM', child: Text('Nhà ngõ hẻm')),
                          DropdownMenuItem(value: 'BIET_THU', child: Text('Biệt thự')),
                          DropdownMenuItem(value: 'LIEN_KE', child: Text('Nhà liền kề')),
                        ],
                        onChanged: (val) => cubit.updateHouseType(val),
                      ),
                      const SizedBox(height: 24),

                      // --- Bedrooms & Bathrooms ---
                      Row(
                        children: [
                          Expanded(
                            child: _CounterField(
                              label: 'Phòng ngủ',
                              value: state.bedrooms ?? 0,
                              onChanged: (val) => cubit.updateBedrooms(val > 0 ? val : null),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CounterField(
                              label: 'Phòng tắm',
                              value: state.bathrooms ?? 0,
                              onChanged: (val) => cubit.updateBathrooms(val > 0 ? val : null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Floors & Door Direction ---
                      Row(
                        children: [
                          Expanded(
                            child: _CounterField(
                              label: 'Tổng số tầng',
                              value: state.totalFloors ?? 0,
                              onChanged: (val) => cubit.updateTotalFloors(val > 0 ? val : null),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Hướng cửa'),
                                const SizedBox(height: 8),
                                _DropdownField(
                                  value: state.doorDirection,
                                  hint: 'Chọn',
                                  items: const [
                                    DropdownMenuItem(value: 'EAST', child: Text('Đông')),
                                    DropdownMenuItem(value: 'WEST', child: Text('Tây')),
                                    DropdownMenuItem(value: 'SOUTH', child: Text('Nam')),
                                    DropdownMenuItem(value: 'NORTH', child: Text('Bắc')),
                                    DropdownMenuItem(value: 'SOUTHEAST', child: Text('Đông Nam')),
                                    DropdownMenuItem(value: 'NORTHEAST', child: Text('Đông Bắc')),
                                    DropdownMenuItem(value: 'SOUTHWEST', child: Text('Tây Nam')),
                                    DropdownMenuItem(value: 'NORTHWEST', child: Text('Tây Bắc')),
                                  ],
                                  onChanged: (val) => cubit.updateDoorDirection(val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Legal Documents ---
                      _buildSectionTitle('Giấy tờ pháp lý'),
                      const SizedBox(height: 12),
                      _DropdownField(
                        value: state.legalDocuments,
                        hint: 'Chọn loại giấy tờ',
                        items: const [
                          DropdownMenuItem(value: 'PINK_BOOK', child: Text('Sổ hồng')),
                          DropdownMenuItem(value: 'RED_BOOK', child: Text('Sổ đỏ')),
                          DropdownMenuItem(value: 'SALE_CONTRACT', child: Text('Hợp đồng mua bán')),
                          DropdownMenuItem(value: 'NONE', child: Text('Chưa có')),
                        ],
                        onChanged: (val) => cubit.updateLegalDocuments(val),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- Furniture Status (Common for both House & Room) ---
                    _buildSectionTitle('Tình trạng nội thất'),
                    const SizedBox(height: 12),
                    _DropdownField(
                      value: state.furnitureStatus,
                      hint: 'Chọn tình trạng',
                      items: const [
                        DropdownMenuItem(value: 'FULL', child: Text('Đầy đủ nội thất')),
                        DropdownMenuItem(value: 'BASIC', child: Text('Nội thất cơ bản')),
                        DropdownMenuItem(value: 'EMPTY', child: Text('Nhà trống')),
                      ],
                      onChanged: (val) => cubit.updateFurnitureStatus(val),
                    ),
                  ],
                ),
              ),

              // --- Bottom Navigation ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _canProceed(state) ? onNext : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAccent,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Tiếp tục',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _kDark,
      ),
    );
  }

  bool _canProceed(CreateListingState state) {
    if (state.propertyType == 'WHOLE_HOUSE') {
      return state.houseType != null &&
          state.bedrooms != null && state.bedrooms! > 0 &&
          state.bathrooms != null && state.bathrooms! > 0 &&
          state.furnitureStatus != null;
    } else {
      return state.furnitureStatus != null;
    }
  }
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kDark),
        ),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _CounterField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                color: value > 0 ? _kDark : Colors.grey.shade400,
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Text(
                value > 0 ? '$value' : '-',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                color: _kAccent,
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
