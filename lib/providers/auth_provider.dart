import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

/// 登录状态（token 是否存在）
final isLoggedInProvider = FutureProvider<bool>(
  (ref) => ref.watch(authRepositoryProvider).isLoggedIn(),
);

/// 当前用户 UserModel
final currentUserProvider = StreamProvider<UserModel?>(
  (ref) => ref.watch(userRepositoryProvider).watchUser(),
);

/// 兼容旧代码：当前 uid（从 UserModel 取）
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.uid;
});

/// 手机号验证码发送状态
final phoneAuthProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthState>(
  (ref) => PhoneAuthNotifier(ref.watch(authRepositoryProvider)),
);

// ── State ──────────────────────────────────────────────────────────────────

enum PhoneAuthStep { idle, sending, codeSent, verifying, done }

class PhoneAuthState {
  final PhoneAuthStep step;
  final String? phone;          // 记住手机号，用于重发
  final String? errorMessage;

  const PhoneAuthState({
    this.step = PhoneAuthStep.idle,
    this.phone,
    this.errorMessage,
  });

  PhoneAuthState copyWith({
    PhoneAuthStep? step,
    String? phone,
    String? errorMessage,
  }) =>
      PhoneAuthState(
        step: step ?? this.step,
        phone: phone ?? this.phone,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class PhoneAuthNotifier extends StateNotifier<PhoneAuthState> {
  final AuthRepository _authRepo;

  PhoneAuthNotifier(this._authRepo) : super(const PhoneAuthState());

  Future<void> sendCode(String phone) async {
    state = state.copyWith(step: PhoneAuthStep.sending, phone: phone, errorMessage: null);
    try {
      await _authRepo.sendCode(phone);
      state = state.copyWith(step: PhoneAuthStep.codeSent);
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
      await _authRepo.verifyCode(phone: phone, code: smsCode);
      state = state.copyWith(step: PhoneAuthStep.done);
    } catch (e) {
      state = state.copyWith(
        step: PhoneAuthStep.codeSent,
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  void reset() => state = const PhoneAuthState();
}
