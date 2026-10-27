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
import '../../../home/presentation/widgets/home_feature_icon.dart';
import '../../data/models/user_profile.dart';

import 'package:material_symbols_icons/symbols.dart';

const kPrimaryDark = Color(0xFF38291F);
const kPrimaryAccent = Color(0xFFD76B28);
const kBackground = Color(0xFFFAF8F5);
const kBorderColor = Color(0xFFEEDFD1);
const kSubText = Color(0xFF8A7464);

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
      backgroundColor: kBackground,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Tài khoản',
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              _profileHeader(context, state),
              const SizedBox(height: 20),
              _membership(context, profile),
              const SizedBox(height: 28),
              const Text(
                'Tiện ích & cài đặt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kPrimaryDark,
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: kBorderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _menu(
                      Symbols.favorite,
                      'Tin đã lưu',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedListingsPage(),
                        ),
                      ),
                    ),
                    _menu(
                      Symbols.home_work,
                      'Khu trọ đã lưu',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedPropertiesPage(),
                        ),
                      ),
                    ),
                    _menu(
                      Symbols.interests,
                      'Sở thích của tôi',
                      () => _editInterests(context),
                    ),
                    _menu(
                      Symbols.report,
                      'Báo cáo sự cố của tôi',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IncidentsPage(),
                        ),
                      ),
                    ),
                    _menu(Symbols.shield, 'Đổi mật khẩu', () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PasswordPage(changePassword: true),
                        ),
                      );
                      if (changed == true && context.mounted) {
                        await logout(context);
                      }
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => logout(context),
                icon: const Icon(Symbols.logout, size: 20),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFAE5141),
                  backgroundColor: const Color(0xFFFFF7F4),
                  side: const BorderSide(color: Color(0xFFF0DAD3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEDDA), Color(0xFFFFFBF5)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      key: const ValueKey('profile-name'),
                      style: const TextStyle(
                        fontSize: 23,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.email,
                      style: const TextStyle(fontSize: 12, color: kSubText),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.phoneNumber ?? 'Chưa cập nhật SĐT',
                      style: const TextStyle(fontSize: 12, color: kSubText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              KeyedSubtree(
                key: const ValueKey('profile-avatar'),
                child: _avatar(context, state),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Hạng $rank',
              key: const ValueKey('profile-rank'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () => _editInterests(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: kSubText,
            ),
            icon: const Icon(Symbols.interests, size: 17),
            label: const Text(
              'Sở thích của tôi',
              style: TextStyle(fontSize: 12),
            ),
          ),
          if (profile.interests.isEmpty)
            const Text(
              'Chọn tối đa 5 sở thích để giới thiệu bản thân.',
              style: TextStyle(fontSize: 12, color: kSubText),
            ),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final code in profile.interests.take(5))
                Chip(
                  label: Text(
                    personalInterestLabels[code] ?? code,
                    style: const TextStyle(fontSize: 12, color: kPrimaryDark),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: kBorderColor),
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
                border: Border.all(color: const Color(0xFFE6C8A9)),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 70,
                  height: 70,
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
    color: Color(0xFFFFE3C2),
    child: Icon(Symbols.person, size: 44, color: Color(0xFFAD6D3F)),
  );

  Widget _membership(BuildContext context, UserProfile profile) {
    final active =
        profile.membershipPackageName != null &&
        profile.subscriptionStatus == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF253A40), Color(0xFF10282F)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1DF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const HomeFeatureIcon(icon: Symbols.payments, size: 48),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'GÓI DỊCH VỤ CỦA BẠN',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8C49A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            profile.membershipPackageName ?? 'Chưa đăng ký gói',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            active
                ? 'Đang sử dụng'
                : profile.membershipPackageName != null
                ? 'Gói hiện không hoạt động'
                : 'Khám phá quyền lợi đăng tin phù hợp với bạn.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFFD4DEDC),
            ),
          ),
          if (active) ...[
            const SizedBox(height: 18),
            const Text(
              'LƯỢT CÒN LẠI',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: Color(0xFFE8C49A),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _quota('Tin thường', profile.remainingStandardQuota),
                _quota('Tin VIP', profile.remainingVipQuota),
                _quota('Làm mới', profile.remainingRefreshQuota),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _packages(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFE4C7),
                foregroundColor: const Color(0xFF573B28),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                active ? 'Xem & nâng cấp gói' : 'Khám phá gói dịch vụ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quota(String label, int? count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF30464A),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '${count ?? '—'} $label',
      style: const TextStyle(fontSize: 12, color: Colors.white),
    ),
  );

  Widget _menu(IconData icon, String title, VoidCallback? onTap) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    leading: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF2E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 21, color: const Color(0xFFAD8A68)),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kPrimaryDark,
      ),
    ),
    subtitle: onTap == null
        ? const Text(
            'Đang phát triển',
            style: TextStyle(fontSize: 11, color: kSubText),
          )
        : null,
    trailing: const Icon(Symbols.chevron_right, size: 18, color: kSubText),
    onTap: onTap,
  );

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
