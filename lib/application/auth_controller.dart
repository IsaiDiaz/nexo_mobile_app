// lib/application/auth_controller.dart (Este archivo se mantiene igual)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/model/registration_data.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthController(this._authRepository, this._ref) : super(AuthState.initial) {
    _checkInitialAuthStatus();

    final disposeListener = _authRepository.pocketBase.authStore.onChange
        .listen((_) {
          _checkInitialAuthStatus();
        });

    _ref.onDispose(() {
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
        avatarPath: avatarPath,
      );
      state = AuthState.authenticated;
      return null;
    } catch (e) {
      state = AuthState.error;
      return e.toString();
    }
  }

  final authControllerProvider =
      StateNotifierProvider<AuthController, AuthState>((ref) {
        final authRepository = ref.watch(authRepositoryProvider);
        return AuthController(authRepository, ref);
      });

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

final currentUserRecordProvider = Provider<pb.RecordModel?>((ref) {
  final authControllerState = ref.watch(authControllerProvider);

  if (authControllerState != AuthState.authenticated) {
    return null;
  }
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentUser;
});

final personProfileProvider = FutureProvider.autoDispose<pb.RecordModel?>((
  ref,
) async {
  final currentUser = ref.watch(currentUserRecordProvider);
  if (currentUser == null) {
    return null;
  }
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getPersonProfile(currentUser.id);
});

final professionalProfileProvider = FutureProvider.autoDispose<pb.RecordModel?>(
  (ref) async {
    final currentUser = ref.watch(currentUserRecordProvider);
    if (currentUser == null) {
      return null;
    }
    final authRepository = ref.watch(authRepositoryProvider);
    return await authRepository.getProfessionalProfile(currentUser.id);
  },
);

final availableUserRolesProvider = Provider<List<UserRole>>((ref) {
  final currentUser = ref.watch(currentUserRecordProvider);
  if (currentUser == null) {
    return [];
  }
  final userRolesData = currentUser.data['role'] as List<dynamic>?;
  List<UserRole> roles = [];
  if (userRolesData != null) {
    for (var roleString in userRolesData) {
      try {
        roles.add(
          UserRole.values.firstWhere(
            (e) => e.name.toUpperCase() == roleString.toString().toUpperCase(),
          ),
        );
      } catch (e) {
        print('Rol desconocido en availableUserRolesProvider: $roleString');
      }
    }
  }
  return roles;
});

final activeRoleProvider = StateProvider<UserRole?>((ref) {
  final availableRoles = ref.watch(availableUserRolesProvider);
  if (availableRoles.isNotEmpty) {
    if (availableRoles.contains(UserRole.client)) {
      return UserRole.client;
    } else if (availableRoles.contains(UserRole.professional)) {
      return UserRole.professional;
    }
  }
  return null;
});
