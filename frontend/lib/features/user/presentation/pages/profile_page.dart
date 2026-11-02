import 'package:frontend/core/theme/app_colors.dart';

import '../../../incident/presentation/incidents_page.dart';
import '../../../preferences/data/models/personal_interests.dart';
import '../../../preferences/data/repositories/preference_repository.dart';
import '../../../../core/layout/app_layout.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../auth/presentation/logout.dart';
import '../../../auth/presentation/pages/password_page.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../preferences/presentation/pages/preferences_page.dart';
import '../../../favorites/presentation/pages/saved_properties_page.dart';
import '../../../listing/presentation/pages/saved_listings_page.dart';
import '../../../membership/presentation/pages/membership_page.dart';
import '../widgets/profile_statistics.dart';
import '../../../listing/presentation/pages/my_listings_page.dart';
import '../../../contract/presentation/pages/my_contracts_page.dart';
import '../../../notification/presentation/notifications_page.dart';
import '../../../notification/presentation/notification_store.dart';
import '../../../content/presentation/system_content_page.dart';
import '../../data/models/user_profile.dart';

import 'package:material_symbols_icons/symbols.dart';

const kPrimaryDark = AppColors.text;
const kPrimaryAccent = AppColors.primary;
const kBackground = AppColors.background;
const kBorderColor = AppColors.border;
const kSubText = AppColors.muted;

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.preferenceRepository});
  final PreferenceRepository? preferenceRepository;
  @override
  Widget build(BuildContext context) =>
      ProfileView(preferenceRepository: preferenceRepository);
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, this.preferenceRepository});
  final PreferenceRepository? preferenceRepository;

  Future<void> _packages(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MembershipPage()),
    );
    if (context.mounted) context.read<ProfileBloc>().add(FetchProfileEvent());
  }

  Future<void> _editInterests(BuildContext context) async {
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => PreferencesPage(
          repository: preferenceRepository,
          onSaved: (interests) {
            if (!profileBloc.isClosed) {
              profileBloc.add(ProfileInterestsSaved(interests));
            }
          },
        ),
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context, ProfileLoaded state) async {
    if (state is! ProfileAvatarUploading) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && context.mounted) {
        if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
          _showConfirmationDialog(context, XFile(pickedFile.path));
        } else {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Căn chỉnh ảnh',
                toolbarColor: kPrimaryAccent,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: false,
              ),
              IOSUiSettings(
                title: 'Căn chỉnh ảnh',
                aspectRatioLockEnabled: false,
              ),
            ],
          );

          if (croppedFile != null && context.mounted) {
            _showConfirmationDialog(context, XFile(croppedFile.path));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    appBar: AppBar(
      centerTitle: true,
      backgroundColor: kBackground,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Cá nhân',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: kPrimaryDark,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Làm mới tài khoản',
          onPressed: () => context.read<ProfileBloc>().add(FetchProfileEvent()),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: kSubText,
            side: const BorderSide(color: kBorderColor),
          ),
          icon: const Icon(Symbols.refresh, size: 21),
        ),
      ],
    ),
    body: AppContent(
      maxWidth: AppLayout.formWidth,
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileAvatarUploadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFAE5141),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryAccent),
            );
          }
          if (state is ProfileError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.cloud_off, size: 42, color: kSubText),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kSubText),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<ProfileBloc>().add(FetchProfileEvent()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! ProfileLoaded) return const SizedBox.shrink();
          final profile = state.profile;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _profileHeader(context, state),
              const SizedBox(height: 12),
              ProfileStatistics(
                profile: profile,
                onListings: () => _openPage(context, const MyListingsPage()),
                onContracts: () =>
                    _openPage(context, const MyContractsPage(isLandlord: true)),
                onSaved: () => _openPage(context, const SavedListingsPage()),
              ),
              const SizedBox(height: 12),
              _membership(context, profile),
              const SizedBox(height: 16),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: kBorderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _menu(
                      Symbols.home,
                      'Thông tin cá nhân',
                      () => _personalInfo(context, profile),
                    ),
                    _menu(
                      Symbols.notifications,
                      'Thông báo',
                      () => _openPage(
                        context,
                        NotificationsPage(store: NotificationScope.of(context)),
                      ),
                    ),
                    _menu(
                      Symbols.assignment,
                      'Quản lý tin đăng',
                      () => _openPage(context, const MyListingsPage()),
                    ),
                    _menu(
                      Symbols.receipt_long,
                      'Quản lý hợp đồng',
                      () => _openPage(
                        context,
                        const MyContractsPage(isLandlord: true),
                      ),
                    ),
                    _menu(
                      Symbols.workspace_premium,
                      'Gói dịch vụ',
                      () => _packages(context),
                    ),
                    _menu(
                      Symbols.interests,
                      'Sở thích của tôi',
                      () => _editInterests(context),
                    ),
                    _menu(
                      Symbols.settings,
                      'Cài đặt',
                      () => _settings(context),
                    ),
                    _menu(
                      Symbols.help,
                      'Trợ giúp',
                      () => _openPage(
                        context,
                        const SystemContentPage(slug: 'guide'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => logout(context),
                icon: const Icon(Symbols.logout, size: 20),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD84D50),
                  side: const BorderSide(color: Color(0xFFE99A9C)),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _profileHeader(BuildContext context, ProfileLoaded state) {
    final profile = state.profile;
    final active = profile.subscriptionStatus == 'ACTIVE';
    final package = profile.membershipPackageName?.toUpperCase() ?? '';
    String rank = 'FREE';
    if (active &&
        package.isNotEmpty &&
        !package.contains('CƠ BẢN') &&
        !package.contains('FREE')) {
      rank = package.replaceFirst('GÓI ', '');
    }
    if (active && package.contains('PRO')) rank = 'PRO';
    if (active && package.contains('PLUS')) rank = 'PLUS';
    final rankColor = rank == 'PRO' ? const Color(0xFF7350AA) : kPrimaryAccent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyedSubtree(
                key: const ValueKey('profile-avatar'),
                child: _avatar(context, state),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _personalInfo(context, profile),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        key: const ValueKey('profile-name'),
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: kPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _contact(
                        Symbols.call,
                        profile.phoneNumber ?? 'Chưa cập nhật SĐT',
                      ),
                      const SizedBox(height: 4),
                      _contact(Symbols.mail, profile.email),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Thông tin cá nhân',
                onPressed: () => _personalInfo(context, profile),
                icon: const Icon(
                  Symbols.chevron_right,
                  size: 20,
                  color: kSubText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hạng $rank',
                  key: const ValueKey('profile-rank'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rankColor,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _editInterests(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: kSubText,
                ),
                icon: const Icon(Symbols.interests, size: 16),
                label: const Text(
                  'Sở thích của tôi',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (profile.interests.isEmpty)
            const Text(
              'Chọn tối đa 5 sở thích để giới thiệu bản thân.',
              style: TextStyle(fontSize: 11, color: kSubText),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final code in profile.interests.take(5))
                Chip(
                  label: Text(
                    personalInterestLabels[code] ?? code,
                    style: const TextStyle(fontSize: 11, color: kPrimaryDark),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  backgroundColor: AppColors.primaryLight,
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context, ProfileLoaded state) {
    final profile = state.profile;
    return Semantics(
      button: true,
      label: 'Đổi ảnh đại diện',
      child: GestureDetector(
        onTap: state is ProfileAvatarUploading
            ? null
            : () => _pickAvatar(context, state),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: profile.avatarUrl?.isNotEmpty == true
                      ? Image.network(
                          profile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
              ),
            ),
            if (state is ProfileAvatarUploading)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(color: kPrimaryAccent),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kPrimaryAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Symbols.photo_camera,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => const ColoredBox(
    color: AppColors.primaryLight,
    child: Icon(Symbols.person, size: 44, color: AppColors.placeholder),
  );

  Widget _membership(BuildContext context, UserProfile profile) {
    final active =
        profile.membershipPackageName != null &&
        profile.subscriptionStatus == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF269C71), AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.workspace_premium,
                size: 30,
                color: Color(0xFFFFDB76),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.membershipPackageName ?? 'Chưa đăng ký gói',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active
                          ? 'Đang sử dụng'
                          : profile.membershipPackageName != null
                          ? 'Gói hiện không hoạt động'
                          : 'Khám phá quyền lợi của bạn',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE0F5E9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _packages(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kPrimaryAccent,
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text(
                  active ? 'Xem gói' : 'Khám phá',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _quota('Tin thường', profile.remainingStandardQuota),
                _quota('Tin VIP', profile.remainingVipQuota),
                _quota('Làm mới', profile.remainingRefreshQuota),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _quota(String label, int? count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '${count ?? '—'} $label',
      style: const TextStyle(fontSize: 10, color: Colors.white),
    ),
  );

  Widget _contact(IconData icon, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: kPrimaryAccent),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 11, color: kSubText),
        ),
      ),
    ],
  );

  Widget _menu(IconData icon, String title, VoidCallback onTap) => Column(
    children: [
      ListTile(
        minTileHeight: 48,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        horizontalTitleGap: 12,
        leading: Icon(icon, size: 23, weight: 400, color: kPrimaryAccent),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: kPrimaryDark,
          ),
        ),
        trailing: const Icon(Symbols.chevron_right, size: 18, color: kSubText),
        onTap: onTap,
      ),
      const Divider(height: 1, indent: 48, endIndent: 14, color: kBorderColor),
    ],
  );

  Future<void> _openPage(BuildContext context, Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (context.mounted) context.read<ProfileBloc>().add(FetchProfileEvent());
  }

  void _personalInfo(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Họ và tên'),
                subtitle: SelectableText(profile.fullName),
              ),
              ListTile(
                title: const Text('Số điện thoại'),
                subtitle: SelectableText(
                  profile.phoneNumber ?? 'Chưa cập nhật',
                ),
              ),
              ListTile(
                title: const Text('Email'),
                subtitle: SelectableText(profile.email),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _settings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menu(Symbols.shield, 'Đổi mật khẩu', () {
                Navigator.pop(sheetContext);
                _changePassword(context);
              }),
              _menu(Symbols.home_work, 'Khu trọ đã lưu', () {
                Navigator.pop(sheetContext);
                _openPage(context, const SavedPropertiesPage());
              }),
              _menu(Symbols.report, 'Báo cáo sự cố của tôi', () {
                Navigator.pop(sheetContext);
                _openPage(context, const IncidentsPage());
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PasswordPage(changePassword: true),
      ),
    );
    if (changed == true && context.mounted) await logout(context);
  }

  void _showConfirmationDialog(BuildContext context, XFile imageFile) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Xác nhận ảnh đại diện',
            style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bạn có muốn sử dụng ảnh này làm ảnh đại diện không?',
                style: TextStyle(color: kSubText),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 60,
                backgroundImage: kIsWeb
                    ? NetworkImage(imageFile.path) as ImageProvider
                    : FileImage(File(imageFile.path)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: kSubText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<ProfileBloc>().add(ChangeAvatarEvent(imageFile));
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }
}
