import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

/// 同步登录状态 — ChangeNotifier，供 GoRouter refreshListenable 使用。
/// 初始值由 main.dart 通过 override 注入（读取本地 token）。
class AuthStateNotifier extends ChangeNotifier {
  bool _isLoggedIn;

  AuthStateNotifier(this._isLoggedIn);

  bool get isLoggedIn => _isLoggedIn;

  void login() {
    if (!_isLoggedIn) {
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  void logout() {
    if (_isLoggedIn) {
      _isLoggedIn = false;
      notifyListeners();
    }
  }
}

final authStateNotifierProvider = ChangeNotifierProvider<AuthStateNotifier>(
  (ref) => AuthStateNotifier(false), // main.dart 会用 override 传入真实值
);

/// 当前用户 UserModel
final currentUserProvider = FutureProvider<UserModel?>((ref) {
  final isLoggedIn = ref.watch(authStateNotifierProvider).isLoggedIn;
  if (!isLoggedIn) return Future.value(null);
  return ref.watch(userRepositoryProvider).watchUser();
});

/// 兼容旧代码：当前 uid（从 UserModel 取）
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.uid;
});

/// 手机号验证码发送状态
final phoneAuthProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthState>(
  (ref) => PhoneAuthNotifier(ref.watch(authRepositoryProvider), ref),
);

// ── State ──────────────────────────────────────────────────────────────────

enum PhoneAuthStep { idle, sending, codeSent, verifying, done }

class PhoneAuthState {
  final PhoneAuthStep step;
  final String? phone;
  final String? errorMessage;
  final String? devCode;
  final String? nextRoute; // 登录成功后跳转路径

  const PhoneAuthState({
    this.step = PhoneAuthStep.idle,
    this.phone,
    this.errorMessage,
    this.devCode,
    this.nextRoute,
  });

  PhoneAuthState copyWith({
    PhoneAuthStep? step,
    String? phone,
    String? errorMessage,
    String? devCode,
    String? nextRoute,
  }) =>
      PhoneAuthState(
        step: step ?? this.step,
        phone: phone ?? this.phone,
        errorMessage: errorMessage ?? this.errorMessage,
        devCode: devCode ?? this.devCode,
        nextRoute: nextRoute ?? this.nextRoute,
      );
}

class PhoneAuthNotifier extends StateNotifier<PhoneAuthState> {
  final AuthRepository _authRepo;
  final Ref _ref;

  PhoneAuthNotifier(this._authRepo, this._ref) : super(const PhoneAuthState());

  Future<void> sendCode(String phone) async {
    state = state.copyWith(
        step: PhoneAuthStep.sending, phone: phone, errorMessage: null);
    try {
      final devCode = await _authRepo.sendCode(phone);
      state = state.copyWith(step: PhoneAuthStep.codeSent, devCode: devCode);
    } catch (e) {
      state = state.copyWith(
        step: PhoneAuthStep.idle,
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  Future<void> verifyCode(String smsCode) async {
    final phone = state.phone;
    if (phone == null) return;

    state = state.copyWith(step: PhoneAuthStep.verifying, errorMessage: null);
    try {
      final data = await _authRepo.verifyCode(phone: phone, code: smsCode);
      _ref.read(authStateNotifierProvider).login();
      // 根据用户完善程度决定跳转路径
      final user = data['user'] as Map<String, dynamic>?;
      final hasName = (user?['childName'] as String?)?.isNotEmpty == true;
      final hasCircle = user?['circleId'] != null;
      final String nextRoute;
      if (!hasName) {
        nextRoute = '/onboarding/profile';
      } else if (!hasCircle) {
        nextRoute = '/onboarding/circle';
      } else {
        nextRoute = '/home';
      }
      state = state.copyWith(step: PhoneAuthStep.done, nextRoute: nextRoute);
    } catch (e) {
      state = state.copyWith(
        step: PhoneAuthStep.codeSent,
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  void reset() => state = const PhoneAuthState();
}
