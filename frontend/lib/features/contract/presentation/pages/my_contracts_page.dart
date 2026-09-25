import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/contract_model.dart';
import '../../data/repositories/contract_repository.dart';
import '../cubit/contract_cubit.dart';

// ─── Design System ───────────────────────────────────────────────────────────
const _kPrimaryDark = Color(0xFF2C1D11);
const _kAccentOrange = Color(0xFFD85D15);
const _kBackground = Color(0xFFFAF8F5);
const _kBorder = Color(0xFFE8DED1);

// ─── Entry Point ─────────────────────────────────────────────────────────────
class MyContractsPage extends StatelessWidget {
  /// Pass true if current user is a landlord (can create contracts).
  final bool isLandlord;

  const MyContractsPage({super.key, this.isLandlord = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ContractCubit(ContractRepository(ApiClient()))
        ..fetchMyContracts(),
      child: _MyContractsView(isLandlord: isLandlord),
    );
  }
}

// ─── View ─────────────────────────────────────────────────────────────────────
class _MyContractsView extends StatelessWidget {
  final bool isLandlord;
  const _MyContractsView({required this.isLandlord});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text(
          'Hợp đồng của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: isLandlord
          ? FloatingActionButton(
              backgroundColor: _kAccentOrange,
              foregroundColor: Colors.white,
              tooltip: 'Tạo hợp đồng mới',
              onPressed: () => _showCreateContractSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: BlocListener<ContractCubit, ContractState>(
        listener: (context, state) {
          if (state is ContractCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tạo hợp đồng thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is ContractError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ContractCubit, ContractState>(
          builder: (context, state) {
            if (state is ContractLoading || state is ContractCreating) {
              return const Center(
                child: CircularProgressIndicator(color: _kAccentOrange),
              );
            }

            if (state is ContractError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccentOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            context.read<ContractCubit>().fetchMyContracts(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ContractLoaded) {
              if (state.contracts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        isLandlord
                            ? 'Bạn chưa tạo hợp đồng nào.\nNhấn + để tạo hợp đồng mới.'
                            : 'Bạn chưa có hợp đồng thuê nào.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: _kAccentOrange,
                onRefresh: () =>
                    context.read<ContractCubit>().fetchMyContracts(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.contracts.length,
                  itemBuilder: (context, index) =>
                      _ContractCard(contract: state.contracts[index]),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showCreateContractSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ContractCubit>(),
        child: const _CreateContractSheet(),
      ),
    );
  }
}

// ─── Contract Card ────────────────────────────────────────────────────────────
class _ContractCard extends StatelessWidget {
  final ContractModel contract;
  const _ContractCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final statusColor = _statusColor(contract.status);
    final statusLabel = _statusLabel(contract.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Listing name + Status chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    contract.listingName ?? 'Phòng #${contract.listingId ?? contract.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 12),

            // Parties
            if (contract.tenantName != null)
              _infoRow(Icons.person_outline, 'Người thuê', contract.tenantName!),
            if (contract.landlordName != null)
              _infoRow(Icons.house_outlined, 'Chủ nhà', contract.landlordName!),

            // Dates
            _infoRow(
              Icons.calendar_today_outlined,
              'Thời hạn',
              '${_formatDate(contract.startDate)} → ${_formatDate(contract.endDate)}',
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 12),

            // Financial info
            Row(
              children: [
                Expanded(
                  child: _financialChip(
                    'Tiền thuê/tháng',
                    currencyFmt.format(contract.monthlyRent),
                    _kAccentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _financialChip(
                    'Tiền cọc',
                    currencyFmt.format(contract.depositAmount),
                    _kPrimaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kPrimaryDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return date;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'EXPIRED':
        return Colors.grey;
      case 'TERMINATED':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Đang hiệu lực';
      case 'EXPIRED':
        return 'Đã hết hạn';
      case 'TERMINATED':
        return 'Đã chấm dứt';
      default:
        return status;
    }
  }
}

// ─── Create Contract BottomSheet ─────────────────────────────────────────────
class _CreateContractSheet extends StatefulWidget {
  const _CreateContractSheet();

  @override
  State<_CreateContractSheet> createState() => _CreateContractSheetState();
}

class _CreateContractSheetState extends State<_CreateContractSheet> {
  final _formKey = GlobalKey<FormState>();
  final _listingIdCtrl = TextEditingController();
  final _tenantIdCtrl = TextEditingController();
  final _monthlyRentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _listingIdCtrl.dispose();
    _tenantIdCtrl.dispose();
    _monthlyRentCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now.add(const Duration(days: 365))),
      firstDate: isStart ? now.subtract(const Duration(days: 30)) : (_startDate ?? now),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _kAccentOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và kết thúc')),
      );
      return;
    }

    final request = CreateContractRequest(
      listingId: int.parse(_listingIdCtrl.text.trim()),
      tenantId: int.parse(_tenantIdCtrl.text.trim()),
      startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
      monthlyRent: double.parse(_monthlyRentCtrl.text.trim()),
      depositAmount: double.parse(_depositCtrl.text.trim()),
    );

    context.read<ContractCubit>().createNewContract(request);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _kBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Tạo Hợp Đồng Mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Thông tin phòng & người thuê'),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _listingIdCtrl,
                        label: 'ID Phòng / Listing',
                        hint: 'Nhập ID phòng cần tạo hợp đồng',
                        icon: Icons.home_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Vui lòng nhập ID Listing' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _tenantIdCtrl,
                        label: 'ID Người thuê',
                        hint: 'Nhập ID người thuê',
                        icon: Icons.person_outline,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Vui lòng nhập ID người thuê' : null,
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Thời gian hợp đồng'),
                      const SizedBox(height: 12),
                      // Date pickers
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerButton(
                              label: 'Ngày bắt đầu',
                              value: _startDate != null ? _dateFmt.format(_startDate!) : null,
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DatePickerButton(
                              label: 'Ngày kết thúc',
                              value: _endDate != null ? _dateFmt.format(_endDate!) : null,
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Thông tin tài chính'),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _monthlyRentCtrl,
                        label: 'Tiền thuê hàng tháng (đ)',
                        hint: 'VD: 3500000',
                        icon: Icons.payments_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập tiền thuê';
                          if (double.tryParse(v) == null) return 'Số không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _depositCtrl,
                        label: 'Tiền cọc (đ)',
                        hint: 'VD: 7000000',
                        icon: Icons.account_balance_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập tiền cọc';
                          if (double.tryParse(v) == null) return 'Số không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kAccentOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Tạo Hợp Đồng',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _kPrimaryDark.withValues(alpha: 0.6)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kAccentOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DatePickerButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: _kPrimaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Chọn ngày',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value != null ? _kPrimaryDark : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
