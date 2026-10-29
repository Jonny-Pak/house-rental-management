import '../../../listing/presentation/widgets/roommate_form.dart';
import '../../../listing/data/models/listing_model.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kite_ui/kite_ui.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../data/models/admin_listing_model.dart';
import '../../data/repositories/admin_listing_repository.dart';
import '../bloc/admin_listing_cubit.dart';
import '../bloc/admin_listing_state.dart';
import '../../../../shared/admin/widgets/states.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, this.repository});
  final AdminListingRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminListingCubit(repository ?? AdminListingRepository(ApiClient())),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatefulWidget {
  const _AdminDashboardView();

  @override
  State<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<_AdminDashboardView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'Tất cả';

  @override
  void initState() {
    super.initState();
    context.read<AdminListingCubit>().fetchPendingListings();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminListingModel> _filterListings(List<AdminListingModel> raw) {
    return raw.where((item) {
      final q = _searchQuery.toLowerCase().trim();
      final matchQuery =
          q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.address.toLowerCase().contains(q) ||
          (item.ownerName?.toLowerCase().contains(q) ?? false) ||
          item.id.toString().contains(q);

      final type = item.listingType ?? item.houseType ?? '';
      final matchType =
          _selectedType == 'Tất cả' || listingTypeLabel(type) == _selectedType;

      return matchQuery && matchType;
    }).toList();
  }

  void _showReviewDialog(BuildContext context, AdminListingModel listing) {
    final c = KiteColors.of(context);
    final t = KiteText.of(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    showDialog(
      context: context,
      builder: (ctx) {
        final compact = MediaQuery.sizeOf(ctx).width < 600;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: KiteRadius.allLg,
            side: BorderSide(color: c.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(KiteSpace.xl),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        if (!compact)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: 0.1),
                              borderRadius: KiteRadius.allSm,
                            ),
                            child: Icon(
                              Icons.home_work_rounded,
                              color: c.primary,
                              size: 20,
                            ),
                          ),
                        if (!compact) const SizedBox(width: KiteSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chi tiết kiểm duyệt #${listing.id}',
                                style: t.h4,
                              ),
                              Text(
                                'Ngày tạo: ${listing.createdAt != null && listing.createdAt!.length >= 10 ? listing.createdAt!.substring(0, 10) : "Mới đây"}',
                                style: t.muted.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!compact)
                          const KiteBadge('Chờ duyệt', tone: KiteTone.warning),
                        if (!compact) const SizedBox(width: KiteSpace.sm),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: c.mutedForeground,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    if (compact)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: KiteBadge('Chờ duyệt', tone: KiteTone.warning),
                      ),
                    const SizedBox(height: KiteSpace.lg),
                    const Divider(height: 1),
                    const SizedBox(height: KiteSpace.lg),

                    // Image gallery preview
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: listing.imageUrls.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: KiteSpace.sm),
                        itemBuilder: (context, index) {
                          return Container(
                            width: 200,
                            decoration: BoxDecoration(
                              color: c.muted,
                              borderRadius: KiteRadius.allMd,
                              border: Border.all(color: c.border),
                            ),
                            child: Image.network(
                              listing.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: KiteSpace.xl),

                    // Information grid
                    Container(
                      padding: const EdgeInsets.all(KiteSpace.lg),
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: KiteRadius.allMd,
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildModalRow(
                            context,
                            'Tiêu đề:',
                            listing.title,
                            isBold: true,
                          ),
                          _buildModalRow(
                            context,
                            'Địa chỉ:',
                            listing.address,
                            icon: Icons.place_outlined,
                          ),
                          _buildModalRow(
                            context,
                            'Giá thuê:',
                            '${currency.format(listing.rentPrice)}/${listingRentUnit(listing.listingType)}',
                            highlight: true,
                          ),
                          _buildModalRow(
                            context,
                            'Diện tích:',
                            '${listing.areaSqm} m²',
                          ),
                          _buildModalRow(
                            context,
                            'Loại hình:',
                            listingTypeLabel(listing.listingType),
                          ),
                          _buildModalRow(
                            context,
                            'Pháp lý:',
                            listing.legalDocuments ?? 'Đầy đủ',
                          ),
                          _buildModalRow(
                            context,
                            'Chủ sở hữu:',
                            '${listing.ownerName ?? "Chủ nhà"} ${listing.ownerPhone != null ? "(${listing.ownerPhone})" : ""}',
                            icon: Icons.person_outline,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KiteSpace.lg),

                    if (listing.roommateInfo != null) ...[
                      RoommateSummary(value: listing.roommateInfo!),
                      const SizedBox(height: KiteSpace.lg),
                    ],
                    // Description
                    Text(
                      'Mô tả chi tiết:',
                      style: t.small.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: KiteSpace.xs),
                    Container(
                      padding: const EdgeInsets.all(KiteSpace.md),
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: KiteRadius.allSm,
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        listing.description.isEmpty
                            ? 'Không có mô tả bổ sung.'
                            : listing.description,
                        style: t.p.copyWith(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: KiteSpace.xl),

                    // Action buttons
                    Wrap(
                      alignment: WrapAlignment.end,
                      runSpacing: KiteSpace.sm,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Đóng'),
                        ),
                        const SizedBox(width: KiteSpace.sm),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _showRejectDialog(context, listing.id);
                          },
                          label: const Text('Từ chối'),
                        ),
                        const SizedBox(width: KiteSpace.sm),
                        FilledButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.read<AdminListingCubit>().approveListing(
                              listing.id,
                            );
                          },
                          label: const Text('Phê duyệt tin'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, int listingId) {
    final reasonController = TextEditingController();
    final c = KiteColors.of(context);
    final t = KiteText.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: KiteRadius.allLg,
            side: BorderSide(color: c.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(KiteSpace.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: c.destructive,
                          size: 22,
                        ),
                        const SizedBox(width: KiteSpace.sm),
                        Expanded(
                          child: Text(
                            'Từ chối bài đăng #$listingId',
                            style: t.h4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KiteSpace.md),
                    Text(
                      'Vui lòng nhập lý do từ chối để gửi phản hồi cho chủ bài đăng.',
                      style: t.muted.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: KiteSpace.lg),
                    KiteTextarea(
                      controller: reasonController,
                      placeholder: 'VD: Hình ảnh không hợp lệ, giá thuê hoặc địa chỉ chưa rõ ràng...',
                    ),
                    const SizedBox(height: KiteSpace.xl),
                    Wrap(
                      alignment: WrapAlignment.end,
                      runSpacing: KiteSpace.sm,
                      children: [
                        KiteButton.ghost(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: KiteSpace.sm),
                        KiteButton.destructive(
                          onPressed: () {
                            final text = reasonController.text.trim();
                            if (text.isEmpty) return;
                            Navigator.of(ctx).pop();
                            context.read<AdminListingCubit>().rejectListing(
                              listingId,
                              text,
                            );
                          },
                          child: const Text('Xác nhận từ chối'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    final emailCtrl = TextEditingController(text: 'thuanln1907@gmail.com');
    final passCtrl = TextEditingController();
    bool busy = false;
    String? err;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final c = KiteColors.of(dialogCtx);
            final t = KiteText.of(dialogCtx);

            return Dialog(
              backgroundColor: c.card,
              shape: RoundedRectangleBorder(
                borderRadius: KiteRadius.allLg,
                side: BorderSide(color: c.border),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(KiteSpace.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: 0.1),
                              borderRadius: KiteRadius.allSm,
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: c.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: KiteSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Đăng nhập Quản trị viên', style: t.h4),
                                Text(
                                  'Xác thực tài khoản Admin hệ thống',
                                  style: t.muted.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: c.mutedForeground,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: KiteSpace.lg),
                      if (err != null) ...[
                        Container(
                          padding: const EdgeInsets.all(KiteSpace.sm),
                          decoration: BoxDecoration(
                            color: c.destructive.withValues(alpha: 0.1),
                            borderRadius: KiteRadius.allSm,
                            border: Border.all(
                              color: c.destructive.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            err!,
                            style: t.small.copyWith(
                              color: c.destructive,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: KiteSpace.md),
                      ],
                      KiteField(
                        label: 'Email',
                        child: KiteInput(
                          controller: emailCtrl,
                          placeholder: 'admin@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      KiteField(
                        label: 'Mật khẩu',
                        child: KiteInput(
                          controller: passCtrl,
                          placeholder: '••••••••',
                          obscure: true,
                        ),
                      ),
                      const SizedBox(height: KiteSpace.lg),
                      KiteButton(
                        leading: busy
                            ? null
                            : const Icon(Icons.login, size: 16),
                        enabled: !busy,
                        onPressed: () async {
                          final em = emailCtrl.text.trim();
                          final pw = passCtrl.text;
                          if (em.isEmpty || pw.isEmpty) {
                            setDialogState(
                              () => err =
                                  'Vui lòng nhập đầy đủ email và mật khẩu.',
                            );
                            return;
                          }
                          setDialogState(() {
                            busy = true;
                            err = null;
                          });

                          try {
                            final client = ApiClient();
                            final res = await client.post('/auth/login', {
                              'email': em,
                              'password': pw,
                            });
                            if (res.statusCode == 200) {
                              final authResponse = AuthResponse.fromJson(
                                res.data as Map<String, dynamic>,
                              );
                              await TokenStorage.saveToken(
                                authResponse.accessToken,
                              );

                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (context.mounted) {
                                KiteToast.show(
                                  context,
                                  title: 'Đăng nhập thành công',
                                  description:
                                      'Đã xác thực tài khoản quản trị viên.',
                                  tone: KiteTone.success,
                                );
                                context
                                    .read<AdminListingCubit>()
                                    .fetchPendingListings();
                              }
                            } else {
                              setDialogState(
                                () => err = 'Đăng nhập không thành công.',
                              );
                            }
                          } on DioException catch (e) {
                            String msg =
                                'Tài khoản hoặc mật khẩu không chính xác.';
                            if (e.response?.data is Map &&
                                e.response?.data['message'] != null) {
                              msg = e.response!.data['message'].toString();
                            }
                            setDialogState(() => err = msg);
                          } catch (e) {
                            setDialogState(
                              () => err = e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              ),
                            );
                          } finally {
                            setDialogState(() => busy = false);
                          }
                        },
                        child: Text(
                          busy ? 'Đang xác thực...' : 'Đăng nhập ngay',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    bool highlight = false,
    IconData? icon,
  }) {
    final c = KiteColors.of(context);
    final t = KiteText.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: t.muted.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (icon != null) ...[
            Icon(icon, size: 14, color: c.mutedForeground),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              value,
              style: t.small.copyWith(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: highlight ? c.primary : c.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = KiteColors.of(context);
    final t = KiteText.of(context);

    return BlocConsumer<AdminListingCubit, AdminListingState>(
      listener: (context, state) {
        if (state is AdminListingActionSuccess) {
          KiteToast.show(
            context,
            title: 'Thành công',
            description: state.message,
            tone: KiteTone.success,
          );
        } else if (state is AdminListingError) {
          KiteToast.show(
            context,
            title: 'Lỗi',
            description: state.message,
            tone: KiteTone.danger,
          );
        }
      },
      builder: (context, state) {
        List<AdminListingModel> rawListings = [];
        if (state is AdminListingLoaded) {
          rawListings = state.pendingListings;
        } else if (context.read<AdminListingCubit>().state
            is AdminListingLoaded) {
          rawListings =
              (context.read<AdminListingCubit>().state as AdminListingLoaded)
                  .pendingListings;
        }

        final filtered = _filterListings(rawListings);
        int roommateListings = 0;
        for (final listing in rawListings) {
          if (listing.listingType == 'SHARED_ROOM') roommateListings++;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(KiteSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duyệt bài đăng', style: t.h3),
                        const SizedBox(height: KiteSpace.xs),
                        Text(
                          'Kiểm duyệt và quản lý các tin đăng cho thuê phòng trọ từ chủ nhà',
                          style: t.muted,
                        ),
                      ],
                    ),
                  ),
                  KiteButton.outline(
                    leading: const Icon(Icons.refresh, size: 15),
                    onPressed: () => context
                        .read<AdminListingCubit>()
                        .fetchPendingListings(),
                    child: const Text('Làm mới'),
                  ),
                ],
              ),
              const SizedBox(height: KiteSpace.xl),

              // Stat Grid
              KiteStatGrid(
                children: [
                  KiteStat(
                    label: 'Tin chờ phê duyệt',
                    value: '${rawListings.length}',
                    delta: rawListings.isEmpty
                        ? 'Đã xử lý hết'
                        : 'Cần kiểm tra',
                    deltaTone: rawListings.isEmpty
                        ? KiteTone.success
                        : KiteTone.warning,
                  ),
                  KiteStat(
                    label: 'Đã lọc theo điều kiện',
                    value: '${filtered.length}',
                    delta: 'Đang hiển thị',
                    deltaTone: KiteTone.info,
                  ),
                  KiteStat(
                    label: 'Diện tích trung bình',
                    value: rawListings.isEmpty
                        ? '0 m²'
                        : '${(rawListings.fold<double>(0, (s, e) => s + e.areaSqm) / rawListings.length).toStringAsFixed(1)} m²',
                    delta: 'Trong hàng đợi',
                    deltaTone: KiteTone.neutral,
                  ),
                  KiteStat(
                    label: 'Tin tìm người ở ghép',
                    value: '$roommateListings',
                    delta: 'Trong hàng đợi',
                    deltaTone: KiteTone.info,
                  ),
                ],
              ),
              const SizedBox(height: KiteSpace.xl),

              // Filter toolbar
              Container(
                padding: const EdgeInsets.all(KiteSpace.md),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: KiteRadius.allMd,
                  border: Border.all(color: c.border),
                ),
                child: Wrap(
                  spacing: KiteSpace.md,
                  runSpacing: KiteSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    // Search box
                    SizedBox(
                      width: 280,
                      child: KiteInput(
                        controller: _searchCtrl,
                        placeholder: 'Tìm theo tiêu đề, địa chỉ, chủ nhà...',
                        leading: Icon(
                          Icons.search,
                          size: 16,
                          color: c.mutedForeground,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    // Type selector pills
                    Wrap(
                      runSpacing: KiteSpace.sm,
                      children: [
                        for (final type in [
                          'Tất cả',
                          'Phòng trọ',
                          'Nhà nguyên căn',
                          'Tìm người ở ghép',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: KiteRadius.allSm,
                              onTap: () => setState(() => _selectedType = type),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedType == type
                                      ? c.primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: KiteRadius.allSm,
                                  border: Border.all(
                                    color: _selectedType == type
                                        ? c.primary
                                        : c.border,
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: t.small.copyWith(
                                    fontSize: 12,
                                    fontWeight: _selectedType == type
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: _selectedType == type
                                        ? c.primary
                                        : c.mutedForeground,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiteSpace.lg),

              // Main Table / List Card
              KiteCard(
                title: 'Danh sách bài đăng cần duyệt',
                trailing: KiteBadge(
                  '${filtered.length} tin',
                  tone: KiteTone.warning,
                ),
                padding: const EdgeInsets.all(KiteSpace.lg),
                child: _buildContent(context, state, rawListings, filtered),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AdminListingState state,
    List<AdminListingModel> raw,
    List<AdminListingModel> filtered,
  ) {
    if (state is AdminListingLoading && raw.isEmpty) {
      return const SizedBox(height: 260, child: LoadingState());
    }

    if (state is AdminListingError && raw.isEmpty) {
      final isAuthError =
          state.message.contains('đăng nhập') ||
          state.message.contains('quyền') ||
          state.message.contains('Admin');

      if (isAuthError) {
        final t = KiteText.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: KiteSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_person_outlined,
                      size: 40,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: KiteSpace.lg),
                  Text(
                    'Yêu cầu quyền Quản trị viên',
                    style: t.h4,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KiteSpace.sm),
                  Text(
                    'Bạn chưa đăng nhập hoặc phiên làm việc đã hết hạn. Vui lòng đăng nhập với tài khoản Quản trị viên để kiểm duyệt bài đăng.',
                    style: t.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KiteSpace.xl),
                  KiteButton(
                    leading: const Icon(Icons.login, size: 16),
                    onPressed: () => _showAdminLoginDialog(context),
                    child: const Text('Đăng nhập tài khoản Admin'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return SizedBox(
        height: 260,
        child: ErrorState(
          message: state.message,
          onRetry: () =>
              context.read<AdminListingCubit>().fetchPendingListings(),
        ),
      );
    }

    if (filtered.isEmpty) {
      return SizedBox(
        height: 260,
        child: EmptyState(
          title: raw.isEmpty
              ? 'Không có bài đăng nào cần duyệt'
              : 'Không có bài đăng phù hợp',
          message: raw.isEmpty
              ? 'Tất cả các tin đăng của chủ nhà đã được kiểm duyệt xong!'
              : 'Hãy thử tìm kiếm với từ khóa khác hoặc bỏ chọn bộ lọc.',
          actionLabel: 'Tải lại danh sách',
          onAction: () {
            setState(() {
              _searchCtrl.clear();
              _searchQuery = '';
              _selectedType = 'Tất cả';
            });
            context.read<AdminListingCubit>().fetchPendingListings();
          },
        ),
      );
    }

    return _buildResponsiveList(context, filtered);
  }

  Widget _buildResponsiveList(
    BuildContext context,
    List<AdminListingModel> items,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 900) return _buildTable(context, items);
      final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(item.address),
                    Text(
                      '${currency.format(item.rentPrice)} • ${item.areaSqm} m²',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showReviewDialog(context, item),
                          child: const Text('Xem xét'),
                        ),
                        FilledButton(
                          onPressed: () => context
                              .read<AdminListingCubit>()
                              .approveListing(item.id),
                          child: const Text('Phê duyệt'),
                        ),
                        TextButton(
                          onPressed: () => _showRejectDialog(context, item.id),
                          child: const Text('Từ chối'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _buildTable(BuildContext context, List<AdminListingModel> items) {
    final c = KiteColors.of(context);
    final t = KiteText.of(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Column(
      children: [
        // Table Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KiteSpace.md,
            vertical: KiteSpace.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  'MÃ',
                  style: t.muted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'THÔNG TIN BÀI ĐĂNG',
                  style: t.muted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'GIÁ & DIỆN TÍCH',
                  style: t.muted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'CHỦ NHÀ',
                  style: t.muted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'NGÀY GỬI',
                  style: t.muted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: Text(
                  'THAO TÁC',
                  textAlign: TextAlign.right,
                  style: t.muted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List items
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KiteSpace.md,
                vertical: KiteSpace.md,
              ),
              child: Row(
                children: [
                  // ID
                  SizedBox(
                    width: 50,
                    child: Text(
                      '#${item.id}',
                      style: t.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.mutedForeground,
                      ),
                    ),
                  ),

                  // Info
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.08),
                            borderRadius: KiteRadius.allMd,
                            border: Border.all(
                              color: c.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.home_work_rounded,
                            color: c.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: KiteSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.small.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 12,
                                    color: c.mutedForeground,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      item.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.muted.copyWith(fontSize: 11.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price & Area
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.format(item.rentPrice),
                          style: t.small.copyWith(
                            fontWeight: FontWeight.bold,
                            color: c.primary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.areaSqm} m²',
                          style: t.muted.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),

                  // Owner
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        KiteAvatar(name: item.ownerName ?? 'Chủ nhà', size: 26),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.ownerName ?? 'Chủ nhà',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.small.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.ownerPhone != null)
                                Text(
                                  item.ownerPhone!,
                                  style: t.muted.copyWith(fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.createdAt != null && item.createdAt!.length >= 10
                          ? item.createdAt!.substring(0, 10)
                          : 'Hôm nay',
                      style: t.muted.copyWith(fontSize: 12),
                    ),
                  ),

                  // Actions
                  SizedBox(
                    width: 240,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        KiteButton.outline(
                          onPressed: () => _showReviewDialog(context, item),
                          child: const Text('Xem xét'),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Duyệt nhanh',
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF0C6B62),
                            size: 20,
                          ),
                          onPressed: () => context
                              .read<AdminListingCubit>()
                              .approveListing(item.id),
                        ),
                        IconButton(
                          tooltip: 'Từ chối',
                          icon: Icon(
                            Icons.cancel_outlined,
                            color: c.destructive,
                            size: 20,
                          ),
                          onPressed: () => _showRejectDialog(context, item.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
