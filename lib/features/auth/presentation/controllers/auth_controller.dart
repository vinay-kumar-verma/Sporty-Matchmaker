import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

enum AuthStatus { idle, loading, otpSent, success, error }

class AuthState {
  final AuthStatus status;
  final String? verificationId;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.idle,
    this.verificationId,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? verificationId,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);
    await _repository.sendOtp(
      phoneNumber: phoneNumber,
      onAutoVerified: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        state = state.copyWith(status: AuthStatus.success);
      },
      onCodeSent: (verificationId) {
        state = state.copyWith(
          status: AuthStatus.otpSent,
          verificationId: verificationId,
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: error,
        );
      },
    );
  }

  Future<bool> verifyOtp(String otp) async {
    if (state.verificationId == null) return false;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.verifyOtp(
        verificationId: state.verificationId!,
        otp: otp,
      );
      state = state.copyWith(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid OTP. Please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final existing =
      await ref.watch(authRepositoryProvider).getUser(user.uid);
  if (existing != null) return existing;
  final newUser = UserModel(
    uid: user.uid,
    phone: user.phoneNumber ?? '',
    name: 'Sporty User',
    sports: [],
    createdAt: DateTime.now(),
  );
  await ref.watch(authRepositoryProvider).saveUser(newUser);
  return newUser;
});