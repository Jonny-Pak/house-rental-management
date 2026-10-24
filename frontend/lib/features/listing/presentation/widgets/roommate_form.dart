import 'package:flutter/material.dart';

import '../../data/models/roommate_info.dart';

class RoommateForm extends StatelessWidget {
  const RoommateForm({super.key, required this.value, required this.onChanged});
  final RoommateInfo value;
  final ValueChanged<RoommateInfo> onChanged;

  Widget _counter(
    String label,
    int count,
    int minimum,
    int maximum,
    ValueChanged<int> update,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        IconButton(
          tooltip: 'Giảm $label',
          onPressed: count > minimum ? () => update(count - 1) : null,
          icon: const Icon(Icons.remove, size: 19),
        ),
        Text(
          '$count',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        IconButton(
          tooltip: 'Tăng $label',
          onPressed: count < maximum ? () => update(count + 1) : null,
          icon: const Icon(Icons.add, size: 19),
          color: const Color(0xFFD76B28),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _counter(
          'Người đang ở',
          value.currentOccupants,
          0,
          19,
          (v) => onChanged(value.copyWith(currentOccupants: v)),
        ),
        _counter(
          'Sức chứa tối đa',
          value.maxOccupants,
          1,
          20,
          (v) => onChanged(value.copyWith(maxOccupants: v)),
        ),
        Text(
          value.isValid
              ? 'Cần tìm thêm ${value.availableSlots} người ở ghép'
              : 'Sức chứa phải lớn hơn số người đang ở.',
          style: TextStyle(
            fontSize: 12,
            color: value.isValid ? const Color(0xFF387960) : Colors.red,
          ),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: value.genderPreference,
          isExpanded: true,
          itemHeight: null,
          decoration: const InputDecoration(labelText: 'Giới tính ưu tiên'),
          items: const [
            DropdownMenuItem(value: 'ANY', child: Text('Không yêu cầu')),
            DropdownMenuItem(value: 'MALE', child: Text('Nam')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(value.copyWith(genderPreference: v));
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Cho phép thú cưng',
            style: TextStyle(fontSize: 13),
          ),
          value: value.allowPets,
          onChanged: (v) => onChanged(value.copyWith(allowPets: v)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Cho phép hút thuốc',
            style: TextStyle(fontSize: 13),
          ),
          value: value.allowSmoking,
          onChanged: (v) => onChanged(value.copyWith(allowSmoking: v)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('roommate-requirements'),
          initialValue: value.roommateRequirements,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Yêu cầu bạn cùng phòng',
            hintText: 'Giờ giấc, vệ sinh, chia sẻ chi phí điện nước…',
          ),
          onChanged: (v) => onChanged(value.copyWith(roommateRequirements: v)),
        ),
      ],
    ),
  );
}

class RoommateSummary extends StatelessWidget {
  const RoommateSummary({super.key, required this.value});
  final RoommateInfo value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Đang ở: ${value.currentOccupants} người · Tối đa: ${value.maxOccupants} người',
      ),
      const SizedBox(height: 8),
      Text(
        'Cần tìm: ${value.availableSlots} người · Ưu tiên: ${value.genderLabel}',
      ),
      const SizedBox(height: 8),
      Text(
        'Thú cưng: ${value.allowPets ? 'Cho phép' : 'Không'} · Hút thuốc: ${value.allowSmoking ? 'Cho phép' : 'Không'}',
      ),
      if (value.roommateRequirements.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('Yêu cầu: ${value.roommateRequirements}'),
      ],
    ],
  );
}
