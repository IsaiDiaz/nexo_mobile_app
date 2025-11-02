import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/data/auth_offline_repository.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/presentation/app.dart';
import 'package:nexo/data/offline_data_sync.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final OfflineAuthRepository _offlineAuthRepository;
  final Ref _ref;

  AuthController(this._authRepository, this._offlineAuthRepository, this._ref)
    : super(AuthState.initial) {
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

      final currentUser = _authRepository.currentUser;
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception("No se pudo obtener el ID del usuario autenticado.");
      }

      final hasPin = await _offlineAuthRepository.hasPinForCurrentUser();
      if (hasPin) {
        print("Usuario ya tiene PIN, guardando sesión local automáticamente.");
        await _offlineAuthRepository.persistOfflineSession("");
      } else {
        print("⚠️ No hay PIN todavía, solicitando creación de PIN.");
        _askForPinAfterLogin();
      }

      final offlineSync = _ref.read(offlineDataSyncProvider);
      await offlineSync.syncUserData();

      state = AuthState.authenticated;
      _ref.read(offlineModeProvider.notifier).state = false;
      print("AuthController: signIn exitoso");
      return null;
    } catch (e) {
      state = AuthState.error;
      return e.toString();
    }
  }

  void _askForPinAfterLogin() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      print(
        "⚠️ rootNavigatorKey.context == null. No se pudo mostrar el diálogo.",
      );
      return;
    }

    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Acceso sin conexión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Crea un PIN de 4 dígitos para poder iniciar sesión sin conexión en el futuro.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'PIN de 4 dígitos',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length < 4) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('El PIN debe tener 4 dígitos')),
                );
                return;
              }

              try {
                await _offlineAuthRepository.persistOfflineSession(pin);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('PIN guardado. Modo offline habilitado.'),
                  ),
                );
              } catch (e) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Error al guardar PIN: $e')),
                );
              }
            },
            child: const Text('Guardar PIN'),
          ),
        ],
      ),
    );
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
        final offlineAuthRepository = ref.watch(offlineAuthRepositoryProvider);
        return AuthController(authRepository, offlineAuthRepository, ref);
      });

  Future<String?> enableOfflineAccess(String pin) async {
    try {
      await _offlineAuthRepository.persistOfflineSession(pin);
      print("💾 Sesión local guardada con PIN para acceso offline.");
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInOffline(String pin) async {
    state = AuthState.loading;
    try {
      final session = await _offlineAuthRepository.signInOffline(pin);
      if (session != null) {
        state = AuthState.authenticated;
        _ref.read(offlineModeProvider.notifier).state = true;
        if (session != null) {
          print("✅ Sesión local encontrada: $session");
        } else {
          print("❌ No se encontró sesión local en SQLite");
        }
        return null;
      } else {
        state = AuthState.error;
        return "No hay sesión almacenada";
      }
    } catch (e) {
      state = AuthState.error;
      return e.toString();
    }
  }

  Future<void> signOut() async {
    state = AuthState.loading;
    await _authRepository.signOut();
    _ref.read(offlineModeProvider.notifier).state = false;
    _ref.invalidate(currentUserRecordProvider);
    _ref.invalidate(availableUserRolesProvider);
    _ref.invalidate(activeRoleProvider);

    state = AuthState.unauthenticated;
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final offlineAuthRepository = ref.watch(offlineAuthRepositoryProvider);
    return AuthController(authRepository, offlineAuthRepository, ref);
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
