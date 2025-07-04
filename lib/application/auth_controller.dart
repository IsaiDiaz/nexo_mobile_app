// lib/application/auth_controller.dart (Este archivo se mantiene igual)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/data/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthController(this._authRepository, this._ref) : super(AuthState.initial) {
    _checkInitialAuthStatus();

    final disposeListener = _authRepository.pocketBase.authStore.onChange.listen((
      _,
    ) {
      print(
        'AuthController: authStore.onChange detectado. Recalculando estado...',
      );
      _checkInitialAuthStatus();
    });

    _ref.onDispose(() {
      print(
        'AuthController: Desechando y cancelando listener de authStore.onChange',
      );
      disposeListener.cancel();
    });
  }

  void _checkInitialAuthStatus() {
    final newAuthState = _authRepository.isAuthenticated
        ? AuthState.authenticated
        : AuthState.unauthenticated;
    if (state != newAuthState) {
      state = newAuthState;
      print('AuthController: _checkInitialAuthStatus actualizado a: $state');
    }
  }

  Future<String?> signIn(String identity, String password) async {
    print("AuthController: Iniciando signIn para $identity");
    state = AuthState.loading;
    try {
      await _authRepository.signIn(identity, password);
      state = AuthState.authenticated;
      print("AuthController: signIn exitoso");
      return null;
    } catch (e) {
      state = AuthState.error;
      return e.toString();
    }
  }

  Future<String?> signUp(
    String email,
    String password,
    String username,
    String passwordConfirm,
    String role,
    String? avatarPath,
  ) async {
    state = AuthState.loading;
    try {
      await _authRepository.signUpWithProfile(
        email: email,
        password: password,
        username: username,
        role: role,
      );
      state = AuthState.authenticated;
      return null;
    } catch (e) {
      state = AuthState.error;
      return e.toString();
    }
  }

  Future<void> signOut() async {
    state = AuthState.loading;
    await _authRepository.signOut();
    state = AuthState.unauthenticated;
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    return AuthController(authRepository, ref);
  },
);

final authStatusProvider = Provider<bool>((ref) {
  final authControllerState = ref.watch(authControllerProvider);
  return authControllerState == AuthState.authenticated;
});

final currentUserProvider = Provider((ref) {
  final authState = ref.watch(authRepositoryProvider);
  return authState == AuthState.authenticated;
});
