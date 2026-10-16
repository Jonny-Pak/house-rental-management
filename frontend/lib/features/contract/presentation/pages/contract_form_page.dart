import '../../../../core/layout/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import '../../data/models/contract_model.dart';
import '../../data/repositories/contract_repository.dart';

class ContractFormPage extends StatefulWidget {
  const ContractFormPage({
    super.key,
    required this.repository,
    this.existing,
    this.listings,
  });
  final ContractRepository repository;
  final ContractModel? existing;
  final ListingRepository? listings;
  @override
  State<ContractFormPage> createState() => _ContractFormPageState();
}

class _ContractFormPageState extends State<ContractFormPage> {
  String _amountText(double? value) {
    if (value == null) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  final _form = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  late final _rentController = TextEditingController(
    text: _amountText(widget.existing?.monthlyRent),
  );
  late final _depositController = TextEditingController(
    text: _amountText(widget.existing?.depositAmount ?? 0),
  );
  late final _noteController = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  List<Listing> _listings = [];
  late int? _selectedListingId = widget.existing?.listingId,
      _selectedTenantId = widget.existing?.tenantId;
  late String? _tenantName = widget.existing?.tenantName;
  late DateTime? _startDate = DateTime.tryParse(
        widget.existing?.startDate ?? '',
      ),
      _endDate = DateTime.tryParse(widget.existing?.endDate ?? '');
  bool _loading = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _contactController,
      _rentController,
      _depositController,
      _noteController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await (widget.listings ?? ListingRepository(ApiClient()))
          .fetchMyListings();
      final availableListings = <Listing>[];
      for (final listing in listings) {
        final isCurrentListing = listing.id == _selectedListingId;
        final isApproved = listing.approvalStatus == 'APPROVED';
        final isAvailable = listing.rentalStatus == 'AVAILABLE';
        if (isCurrentListing || (isApproved && isAvailable)) {
          availableListings.add(listing);
        }
      }
      if (mounted) {
        setState(() => _listings = availableListings);
      }
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _lookup() async {
    if (_selectedListingId == null || _contactController.text.trim().isEmpty) {
      setState(
        () => _error =
            'Chọn tin đăng và nhập email hoặc số điện thoại người thuê.',
      );
      return;
    }
    final contact = _contactController.text.trim();
    final listing = _selectedListingId!;
    setState(() => _busy = true);
    try {
      final result = await widget.repository.findTenant(contact, listing);
      if (!mounted) return;
      if (contact != _contactController.text.trim()) return;
      if (listing != _selectedListingId) return;

      setState(() {
        _selectedTenantId = result['id'] as int;
        _tenantName = result['name'] as String;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(bool start) async {
    DateTime? selectedDate;
    if (start) {
      selectedDate = _startDate;
    } else {
      selectedDate = _endDate;
    }
    final initial = selectedDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() {
        if (start) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedListingId == null ||
        _selectedTenantId == null ||
        _startDate == null ||
        _endDate == null) {
      setState(() => _error = 'Chọn tin đăng, người thuê và thời hạn.');
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      setState(() => _error = 'Ngày kết thúc phải sau ngày bắt đầu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final request = CreateContractRequest(
      listingId: _selectedListingId!,
      tenantId: _selectedTenantId!,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
      monthlyRent: double.parse(_rentController.text),
      depositAmount: double.parse(_depositController.text),
      note: _noteController.text.trim(),
    );
    try {
      if (widget.existing == null) {
        await widget.repository.createContract(request);
      } else {
        await widget.repository.update(widget.existing!.id, request);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateAmount(String? text, bool isRent) {
    final amount = double.tryParse(text ?? '');
    if (amount == null || !amount.isFinite) {
      return 'Nhập số tiền hợp lệ.';
    }
    if (amount > 9999999999.99) {
      return 'Nhập số tiền hợp lệ.';
    }
    if (isRent && amount <= 0) {
      return 'Nhập số tiền hợp lệ.';
    }
    if (!isRent && amount < 0) {
      return 'Nhập số tiền hợp lệ.';
    }
    if (text != null && text.contains('.')) {
      final decimalPart = text.split('.').last;
      if (decimalPart.length > 2) {
        return 'Nhập số tiền hợp lệ.';
      }
    }
    return null;
  }

  List<DropdownMenuItem<int>> _listingOptions() {
    final options = <DropdownMenuItem<int>>[];
    for (final listing in _listings) {
      options.add(
        DropdownMenuItem(
          value: listing.id,
          child: Text(
            listing.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    return options;
  }

  void _selectListing(int? listingId) {
    setState(() {
      _selectedListingId = listingId;
      _selectedTenantId = null;
      _tenantName = null;
      _contactController.clear();
      for (final listing in _listings) {
        if (listing.id == listingId) {
          _rentController.text = listing.rentPrice.toInt().toString();
          break;
        }
      }
    });
  }

  Widget _amount(String name, TextEditingController c, {bool rent = false}) =>
      TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(labelText: name),
        validator: (value) => _validateAmount(value, rent),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.existing == null ? 'Tạo hợp đồng' : 'Sửa bản nháp'),
    ),
    body: AppContent(
      maxWidth: AppLayout.formWidth,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_listings.isEmpty) ...[
                    const Text('Bạn chưa có tin đã duyệt đang cho thuê.'),
                    TextButton(onPressed: _load, child: const Text('Tải lại')),
                  ],
                  DropdownButtonFormField<int>(
                    initialValue: _selectedListingId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tin cho thuê của bạn',
                    ),
                    items: _listingOptions(),
                    onChanged: _busy || widget.existing != null
                        ? null
                        : _selectListing,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _contactController,
                    enabled: !_busy,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Email hoặc số điện thoại người thuê',
                    ),
                    onChanged: (_) => setState(() {
                      _selectedTenantId = null;
                      _tenantName = null;
                    }),
                  ),
                  TextButton(
                    onPressed: _busy || _selectedListingId == null
                        ? null
                        : _lookup,
                    child: const Text('Tìm người thuê'),
                  ),
                  if (_tenantName != null)
                    Text(
                      'Người thuê: $_tenantName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 20),
                  ResponsiveCards(
                    minCardWidth: 280,
                    children: [
                      OutlinedButton(
                        onPressed: _busy ? null : () => _pick(true),
                        child: Text(
                          'Bắt đầu: ${_startDate == null ? 'Chọn ngày' : DateFormat('dd/MM/yyyy').format(_startDate!)}',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : () => _pick(false),
                        child: Text(
                          'Kết thúc: ${_endDate == null ? 'Chọn ngày' : DateFormat('dd/MM/yyyy').format(_endDate!)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ResponsiveCards(
                    minCardWidth: 280,
                    children: [
                      _amount(
                        'Tiền thuê / tháng (VNĐ)',
                        _rentController,
                        rent: true,
                      ),
                      _amount('Tiền cọc (VNĐ)', _depositController),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú / thỏa thuận thêm',
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy || _listings.isEmpty ? null : _save,
                    child: Text(
                      _busy ? 'Đang xử lý…' : 'Lưu và chờ người thuê xác nhận',
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}
