import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../data/repositories/user_repository.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../preferences/presentation/pages/preferences_page.dart';
import '../../../favorites/presentation/pages/saved_properties_page.dart';

// ─── Design System Colors ─────────────────────────────────────────────
const kPrimaryDark   = Color(0xFF2C1D11);
const kPrimaryAccent = Color(0xFFD85D15);
const kBackground    = Color(0xFFFAF8F5);
const kBorderColor   = Color(0xFFE8DED1);
const kSubText       = Color(0xFF64748B);
// ──────────────────────────────────────────────────────────────────────

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // Typically dependencies are injected via get_it or similar, but for simplicity:
        final apiClient = ApiClient();
        final remoteDataSource = UserRemoteDataSourceImpl(apiClient);
        final repository = UserRepositoryImpl(remoteDataSource);
        
        return ProfileBloc(repository)..add(FetchProfileEvent());
      },
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            color: kPrimaryDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileAvatarUploadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          } else if (state is ProfileLoaded && state is! ProfileAvatarUploading && state is! ProfileAvatarUploadError) {
            // Optional: Show success message when avatar successfully uploaded? 
            // We can just rely on the UI update.
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryAccent));
          } else if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${state.message}', style: const TextStyle(color: kSubText)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryAccent, foregroundColor: Colors.white),
                    onPressed: () => context.read<ProfileBloc>().add(FetchProfileEvent()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          } else if (state is ProfileLoaded) {
            final profile = state.profile;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- User Info Card ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBorderColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (state is! ProfileAvatarUploading) {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                              
                              if (pickedFile != null && context.mounted) {
                                // image_cropper does not support Windows/Linux desktop natively yet.
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
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kPrimaryAccent.withValues(alpha: 0.3), width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: kPrimaryAccent.withValues(alpha: 0.1),
                                  backgroundImage: profile.avatarUrl != null
                                      ? NetworkImage(profile.avatarUrl!)
                                      : null,
                                  child: profile.avatarUrl == null
                                      ? const Icon(Icons.person, size: 48, color: kPrimaryAccent)
                                      : null,
                                ),
                              ),
                              if (state is ProfileAvatarUploading)
                                Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: kPrimaryAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: const TextStyle(
                            fontSize: 15,
                            color: kSubText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_iphone, size: 16, color: kPrimaryDark),
                              const SizedBox(width: 8),
                              Text(
                                profile.phoneNumber ?? 'Chưa cập nhật SĐT',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kPrimaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // --- Menu Items ---
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'Cài đặt chung',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryDark,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: kBorderColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.favorite_border,
                          iconColor: Colors.redAccent,
                          title: 'Tin đã lưu',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SavedPropertiesPage()),
                            );
                          },
                        ),
                        const Divider(color: kBorderColor, height: 1, indent: 56),
                        _buildMenuItem(
                          icon: Icons.tune_rounded,
                          iconColor: Colors.blueAccent,
                          title: 'Sở thích tìm kiếm',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PreferencesPage()),
                            );
                          },
                        ),
                        const Divider(color: kBorderColor, height: 1, indent: 56),
                        _buildMenuItem(
                          icon: Icons.shield_outlined,
                          iconColor: Colors.green,
                          title: 'Đổi mật khẩu',
                          onTap: () {
                            // TODO: Change password
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // --- Logout Button ---
                  OutlinedButton.icon(
                    onPressed: () {
                      // Implement logout logic
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    label: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: kPrimaryDark,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kSubText),
      onTap: onTap,
    );
  }

  void _showConfirmationDialog(BuildContext context, XFile imageFile) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận ảnh đại diện', style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bạn có muốn sử dụng ảnh này làm ảnh đại diện không?', style: TextStyle(color: kSubText)),
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
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryAccent, foregroundColor: Colors.white),
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
