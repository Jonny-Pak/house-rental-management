import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/auth/data/models/auth_models.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/home/presentation/pages/main_page.dart';
import 'package:frontend/features/user/data/models/user_profile.dart';
import 'package:frontend/features/user/data/repositories/user_repository.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResponse> login(LoginRequest request) async => const AuthResponse(
    accessToken: 'test-token',
    refreshToken: '',
    userId: 1,
    role: 'MEMBER',
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserRepository implements UserRepository {
  @override
  Future<UserProfile> getProfile() async => const UserProfile(
    id: 1,
    fullName: 'Người dùng thử',
    email: 'tenant@example.com',
  );
  @override
  Future<UserProfile> updateAvatar(String url) => getProfile();
  @override
  Future<String> uploadImage(XFile file) async => '';
}

void main() {
  for (final fromProfile in [true, false]) {
    testWidgets(
      'Logout from ${fromProfile ? 'profile' : 'drawer'} clears session and root history',
      (tester) async {
        SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
        await tester.binding.setSurfaceSize(const Size(430, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final bloc = AuthBloc(FakeAuthRepository());
        bloc.add(
          const LoginRequested(
            LoginRequest(
              email: 'tenant@example.com',
              password: 'test-password',
            ),
          ),
        );
        await bloc.stream.firstWhere((state) => state is AuthAuthenticated);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              navigatorKey: navigator,
              home: const Scaffold(body: Text('Previous page')),
            ),
          ),
        );
        navigator.currentState!.push(
          MaterialPageRoute(
            builder: (_) => MainPage(userRepository: FakeUserRepository()),
          ),
        );
        await tester.pumpAndSettle();
        if (fromProfile) {
          await tester.tap(find.byTooltip('Tài khoản'));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Đăng xuất'),
            300,
            scrollable: find.byType(Scrollable).last,
          );
        } else {
          await tester.tap(find.byTooltip('Mở menu'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Đăng xuất'));
        await tester.pumpAndSettle();
        expect(await TokenStorage.getToken(), isNull);
        expect(bloc.state, isA<AuthUnauthenticated>());
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(MainPage), findsNothing);
        expect(navigator.currentState!.canPop(), isFalse);
        expect(await navigator.currentState!.maybePop(), isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => bloc.close());
      },
    );
  }
}
