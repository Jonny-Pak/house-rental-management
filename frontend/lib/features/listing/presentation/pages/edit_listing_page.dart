import '../../../../core/layout/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/listing_model.dart';
import '../../data/repositories/listing_repository.dart';
import '../widgets/listing_area_selector.dart';

class EditListingPage extends StatefulWidget {
  const EditListingPage({
    super.key,
    required this.listing,
    required this.repository,
  });
  final Listing listing;
  final ListingRepository repository;

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  int? _areaId;
  bool _busy = false;
  bool _changeArea = false;
  late final List<String> _images;
  final List<XFile> _newImages = [];

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _areaId = l.areaId;
    _images = [...l.imageUrls];
    _fields = {
      'title': TextEditingController(text: l.title),
      'description': TextEditingController(text: l.description),
      'address': TextEditingController(text: l.address),
      'rentPrice': TextEditingController(text: '${l.rentPrice}'),
      'areaSqm': TextEditingController(text: '${l.areaSqm}'),
      'latitude': TextEditingController(text: '${l.latitude ?? ''}'),
      'longitude': TextEditingController(text: '${l.longitude ?? ''}'),
    };
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_areaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn phường/xã.')));
      return;
    }
    if (_images.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một ảnh.')),
      );
      return;
    }
    setState(() => _busy = true);
    final l = widget.listing;
    final request = <String, dynamic>{
      for (final key in [
        'houseType',
        'bedrooms',
        'bathrooms',
        'totalFloors',
        'doorDirection',
        'legalDocuments',
        'furnitureStatus',
        'depositAmount',
        'posterType',
      ])
        key: l.details[key],
      'listingType': l.listingType,
      'areaId': _areaId,
      'imageUrls': [..._images],
    };
    for (final entry in _fields.entries) {
      request[entry.key] =
          ['rentPrice', 'areaSqm', 'latitude', 'longitude'].contains(entry.key)
          ? double.parse(entry.value.text.trim().replaceAll(',', '.'))
          : entry.value.text.trim();
    }
    try {
      for (final file in _newImages) {
        (request['imageUrls'] as List<String>).add(
          await widget.repository.uploadImage(file.path),
        );
      }
      await widget.repository.updateListing(l.id, request);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ListingRepository.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    String key,
    String label, {
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _fields[key],
        decoration: InputDecoration(labelText: label),
        maxLines: maxLines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : null,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (key == 'description') return null;
          if (text.isEmpty) return 'Vui lòng nhập $label';
          if (number) {
            final n = double.tryParse(text.replaceAll(',', '.'));
            if (n == null || !n.isFinite) return 'Giá trị không hợp lệ';
            if (['rentPrice', 'areaSqm'].contains(key) && n <= 0) {
              return 'Giá trị phải lớn hơn 0';
            }
            if (key == 'latitude' && n.abs() > 90 ||
                key == 'longitude' && n.abs() > 180) {
              return 'Tọa độ không hợp lệ';
            }
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sửa tin đăng')),
    body: AppContent(
      maxWidth: AppLayout.formWidth,
      child: AbsorbPointer(
        absorbing: _busy,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Sau khi lưu, tin sẽ tạm ngừng xuất hiện trên bản đồ để Admin duyệt lại.',
              ),
              const SizedBox(height: 20),
              _field('title', 'Tiêu đề'),
              _field('description', 'Mô tả', maxLines: 4),
              _field('rentPrice', 'Giá thuê (VND/tháng)', number: true),
              _field('areaSqm', 'Diện tích (m²)', number: true),
              _field('address', 'Địa chỉ'),
              _field('latitude', 'Vĩ độ', number: true),
              _field('longitude', 'Kinh độ', number: true),
              const Text('Ảnh tin đăng (1–10 ảnh)'),
              Wrap(
                spacing: 8,
                children: [
                  for (final url in _images)
                    InputChip(
                      label: SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                      onDeleted: () => setState(() => _images.remove(url)),
                    ),
                  for (final file in _newImages)
                    InputChip(
                      label: Text(file.name),
                      onDeleted: () => setState(() => _newImages.remove(file)),
                    ),
                ],
              ),
              TextButton.icon(
                onPressed: _images.length + _newImages.length >= 10
                    ? null
                    : () async {
                        final files = await ImagePicker().pickMultiImage();
                        if (mounted) {
                          setState(
                            () => _newImages.addAll(
                              files.take(
                                10 - _images.length - _newImages.length,
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Thêm ảnh'),
              ),
              SwitchListTile(
                title: const Text('Thay đổi khu vực hành chính'),
                value: _changeArea,
                onChanged: (value) => setState(() {
                  _changeArea = value;
                  _areaId = value ? null : widget.listing.areaId;
                }),
              ),
              if (_changeArea)
                ListingAreaSelector(onChanged: (id) => _areaId = id),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Đang lưu…' : 'Lưu và gửi duyệt lại'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
