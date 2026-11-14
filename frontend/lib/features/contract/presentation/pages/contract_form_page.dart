import '../../../../core/layout/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/excel/excel_page.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import '../../data/models/contract_model.dart';
import '../../data/repositories/contract_repository.dart';
import '../widgets/contract_terms_form.dart';
import '../widgets/contract_document_view.dart';

class ContractFormPage extends StatefulWidget {
  const ContractFormPage({super.key, required this.repository, this.listings});
  final ContractRepository repository;
  final ListingRepository? listings;
  @override
  State<ContractFormPage> createState() => _ContractFormPageState();
}

class _ContractFormPageState extends State<ContractFormPage> {
  final _form = GlobalKey<FormState>();
  final _terms = GlobalKey<ContractTermsFormState>();
  final _contactController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _noteController = TextEditingController();
  List<Listing> _listings = [];
  int? _selectedListingId, _selectedTenantId;
  String? _tenantName;
  DateTime? _startDate, _endDate;
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
      details: _terms.currentState!.values(
        DateFormat('yyyy-MM-dd').format(_startDate!),
      ),
    );
    try {
      final content = await widget.repository.preview(request);
      if (!mounted) return;
      final confirmed = await _preview(content);
      if (confirmed != true || !mounted) return;
      await widget.repository.createContract(request);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importExcel() async {
    if (_busy) return;
    final imported = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => const ExcelPage(
          module: 'contracts',
          title: 'Hợp đồng',
          allowImport: true,
        ),
      ),
    );
    if (imported != null && mounted) Navigator.pop(context, true);
  }

  Widget _section(String title, IconData icon, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDCE9E1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF187C45)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Future<bool?> _preview(String content) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppLayout.formWidth,
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Xem trước hợp đồng',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ContractDocumentView(content: content),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Quay lại chỉnh sửa'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Xác nhận gửi hợp đồng'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

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
    appBar: AppBar(title: const Text('Tạo hợp đồng')),
    body: AppContent(
      maxWidth: AppLayout.formWidth,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6EE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lập hợp đồng thuê',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF174C32),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Điền thông tin, xem trước bản Word và gửi cho người thuê xác nhận. Sau khi tạo, hợp đồng được khóa chỉnh sửa.',
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _importExcel,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Nhập hợp đồng từ file Excel'),
                    ),
                    const SizedBox(height: 16),
                    if (_listings.isEmpty) ...[
                      const Text('Bạn chưa có tin đã duyệt đang cho thuê.'),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Tải lại'),
                      ),
                    ],
                    _section(
                      'Tin cho thuê và người thuê',
                      Icons.people_alt_outlined,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: _selectedListingId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Tin cho thuê của bạn',
                            ),
                            items: _listingOptions(),
                            onChanged: _busy ? null : _selectListing,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _section(
                      'Thời hạn và chi phí',
                      Icons.calendar_month_outlined,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                        ],
                      ),
                    ),
                    _section(
                      'Thông tin điền vào mẫu hợp đồng',
                      Icons.description_outlined,
                      ContractTermsForm(key: _terms),
                    ),
                    _section(
                      'Thỏa thuận bổ sung',
                      Icons.notes_rounded,
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú / thỏa thuận thêm',
                        ),
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
                        _busy
                            ? 'Đang xử lý…'
                            : 'Lưu và chờ người thuê xác nhận',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}
