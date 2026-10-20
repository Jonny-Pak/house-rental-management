import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/app_layout.dart';

class ContractTermsForm extends StatefulWidget {
  const ContractTermsForm({super.key, this.initial = const {}});
  final Map<String, dynamic> initial;
  @override
  State<ContractTermsForm> createState() => ContractTermsFormState();
}

class ContractTermsFormState extends State<ContractTermsForm> {
  final _fields = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    final defaults = <String, String>{
      'landlordIdentity': '',
      'landlordAddress': '',
      'tenantIdentity': '',
      'tenantAddress': '',
      'signingPlace': '',
      'signingDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'handoverDate': '',
      'paymentDay': '5',
      'paymentMethod': '',
      'electricityTerms': '',
      'waterTerms': '',
      'serviceFees':
          'Không thu thêm nếu hai bên không có thỏa thuận bằng văn bản.',
      'conditionDescription':
          'Hiện trạng được hai bên kiểm tra và ghi nhận khi bàn giao.',
      'equipment': 'Theo danh mục hai bên kiểm tra và ghi nhận khi bàn giao.',
      'useRules': 'Sử dụng để ở; giữ vệ sinh, an ninh, phòng cháy; không sửa chữa hoặc cho thuê lại khi chưa có thỏa thuận hợp lệ.',
      'depositTerms': 'Đối chiếu tiền thuê, điện nước và tài sản khi bàn giao; hoàn lại tiền cọc còn lại. Các khoản khấu trừ phải có căn cứ và được hai bên xác nhận.',
      'terminationTerms': 'Báo trước 30 ngày theo thỏa thuận; đối chiếu nghĩa vụ và lập biên bản bàn giao khi kết thúc, phù hợp quy định pháp luật áp dụng.',
      'violationTerms': 'Bồi thường thiệt hại thực tế do lỗi của bên vi phạm. Các khoản phạt khác phải được hai bên thỏa thuận hợp pháp.',
    };
    for (final key in defaults.keys) {
      _fields[key] = TextEditingController(
        text: widget.initial[key]?.toString() ?? defaults[key],
      );
    }
  }

  Map<String, dynamic> values(String startDate) {
    final result = <String, dynamic>{};
    for (final key in _fields.keys) {
      result[key] = _fields[key]!.text.trim();
    }
    result['paymentDay'] = int.tryParse(_fields['paymentDay']!.text) ?? 0;
    if (result['handoverDate'] == '') result['handoverDate'] = startDate;
    return result;
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _field(
    String key,
    String label, {
    int lines = 2,
    bool date = false,
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey(key),
      controller: _fields[key],
      minLines: 1,
      maxLines: lines,
      maxLength: key == 'signingPlace'
          ? 255
          : (key.contains('Identity') || key.contains('Address') ? 500 : 1000),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        helperText: date ? 'yyyy-MM-dd' : null,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return optional ? null : 'Cần nhập $label';
        }
        if (date) {
          final parsed = DateTime.tryParse(value);
          if (parsed == null ||
              DateFormat('yyyy-MM-dd').format(parsed) != value) {
            return 'Nhập ngày theo yyyy-MM-dd';
          }
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading('Thông tin hai bên'),
      const Text(
        'Họ tên và điện thoại lấy từ tài khoản. Nhập số giấy tờ, ngày cấp và nơi cấp vào cùng ô giấy tờ tùy thân.',
      ),
      const SizedBox(height: 12),
      _field('landlordIdentity', 'Giấy tờ tùy thân chủ nhà'),
      _field('landlordAddress', 'Địa chỉ chủ nhà'),
      _field('tenantIdentity', 'Giấy tờ tùy thân người thuê'),
      _field('tenantAddress', 'Địa chỉ người thuê'),
      _heading('Lập hợp đồng và bàn giao'),
      _field('signingPlace', 'Địa điểm lập hợp đồng'),
      ResponsiveCards(
        minCardWidth: 280,
        children: [
          _field('signingDate', 'Ngày lập hợp đồng', lines: 1, date: true),
          _field(
            'handoverDate',
            'Ngày bàn giao (trống: ngày bắt đầu)',
            lines: 1,
            date: true,
            optional: true,
          ),
        ],
      ),
      _field('conditionDescription', 'Hiện trạng nhà/phòng'),
      _field('equipment', 'Trang thiết bị và tài sản kèm theo'),
      _heading('Thanh toán và chi phí'),
      TextFormField(
        key: const ValueKey('paymentDay'),
        controller: _fields['paymentDay'],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Ngày thanh toán hằng tháng (1–28)',
        ),
        validator: (value) {
          final day = int.tryParse(value ?? '');
          return day == null || day < 1 || day > 28
              ? 'Chọn ngày từ 1 đến 28'
              : null;
        },
      ),
      const SizedBox(height: 16),
      _field('paymentMethod', 'Phương thức / tài khoản nhận tiền'),
      _field('electricityTerms', 'Tiền điện: đơn giá, cách tính, hạn trả'),
      _field('waterTerms', 'Tiền nước: đơn giá, cách tính, hạn trả'),
      _field('serviceFees', 'Wifi, dịch vụ và các phí khác'),
      _heading('Điều khoản hai bên thỏa thuận'),
      _field('useRules', 'Mục đích, nội quy và số người ở', lines: 4),
      _field('depositTerms', 'Hoàn trả và khấu trừ tiền cọc', lines: 4),
      _field('terminationTerms', 'Chấm dứt và thời hạn báo trước', lines: 4),
      _field('violationTerms', 'Xử lý vi phạm và bồi thường', lines: 4),
    ],
  );
}
