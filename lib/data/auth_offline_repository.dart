import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/data/local/session_local.dart';
import 'package:nexo/data/local/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflineAuthRepository {
  final AuthRepository _authRepository;
  final LocalSessionRepository _localSession = LocalSessionRepository();
  final SecureStorageService _secureStorage = SecureStorageService();

  OfflineAuthRepository(this._authRepository);

  Future<void> persistOfflineSession(String pin) async {
    final user = _authRepository.currentUser;
    if (user == null) throw Exception("No hay usuario autenticado");

    final userId = user.id;

    // 🔹 Guarda el PIN asociado al usuario
    await _secureStorage.savePin(pin, userId);

    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionData = {
      'id': 1,
      'user_id': userId,
      'email': user.getStringValue('email'),
      'name': user.getStringValue('name'),
      'role': (user.data['role'] is List)
          ? (user.data['role'] as List).join(',')
          : user.data['role'].toString(),
      'jwt_token': _authRepository.pocketBase.authStore.token,
      'jwt_expires_at': now + (24 * 3600 * 1000),
      'created_at': now,
      'updated_at': now,
    };

    await _localSession.saveSession(sessionData);

    print(" Sesión offline guardada para el usuario $userId");
    print(" PIN guardado para el usuario $userId");
    print("datos de sesión: $sessionData");
  }

  Future<void> persistOfflineSessionIfPossible() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    final hasPin = await _secureStorage.hasPin(user.id);
    if (!hasPin) {
      print("⚠️ No hay PIN todavía, solicitando creación de PIN.");
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionData = {
      'id': 1,
      'user_id': user.id,
      'email': user.getStringValue('email'),
      'name': user.getStringValue('name'),
      'role': (user.data['role'] is List)
          ? (user.data['role'] as List).join(',')
          : user.data['role'].toString(),
      'jwt_token': _authRepository.pocketBase.authStore.token,
      'jwt_expires_at': now + (24 * 3600 * 1000),
      'created_at': now,
      'updated_at': now,
    };

    await _localSession.saveSession(sessionData);
    print("💾 Sesión offline actualizada automáticamente");
  }

  Future<Map<String, dynamic>?> signInOffline(String pin) async {
    final session = await _localSession.getSession();
    print("🧠 Sesión SQLite recuperada: $session");
    if (session == null) throw Exception("No hay sesión guardada localmente");

    final userId = session['user_id'];
    final valid = await _secureStorage.verifyPin(pin, userId);
    print("🔐 Verificación de PIN: $valid (userId=$userId)");

    if (!valid) throw Exception("PIN incorrecto");
    return session;
  }

  Future<bool> hasPinForCurrentUser() async {
    final user = _authRepository.currentUser;
    if (user == null) return false;
    return _secureStorage.hasPin(user.id);
  }

  Future<Map<String, dynamic>?> getLocalSession() async {
    return _localSession.getSession();
  }

  Future<void> clearOfflineSession() async {
    final session = await _localSession.getSession();
    if (session != null) {
      await _secureStorage.clearPin(session['user_id']);
    }
    await _localSession.clearSession();
  }
}

final offlineAuthRepositoryProvider = Provider<OfflineAuthRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return OfflineAuthRepository(authRepo);
});

final offlineModeProvider = StateProvider<bool>((_) => false);
