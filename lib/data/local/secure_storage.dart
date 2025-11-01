import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  /// Guarda el PIN hash vinculado al userId
  Future<void> savePin(String pin, String userId) async {
    final hash = _hashPin(pin);
    await _storage.write(key: 'offline_pin_$userId', value: hash);
  }

  /// Verifica si ya existe un PIN para este usuario
  Future<bool> hasPin(String userId) async {
    final saved = await _storage.read(key: 'offline_pin_$userId');
    return saved != null && saved.isNotEmpty;
  }

  /// Verifica si el PIN ingresado coincide con el del usuario
  Future<bool> verifyPin(String pin, String userId) async {
    final savedHash = await _storage.read(key: 'offline_pin_$userId');
    if (savedHash == null) return false;
    return savedHash == _hashPin(pin);
  }

  /// Limpia solo el PIN de un usuario específico
  Future<void> clearPin(String userId) async {
    await _storage.delete(key: 'offline_pin_$userId');
  }

  /// Limpia todo (todos los usuarios)
  Future<void> clearAll() async => _storage.deleteAll();

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<String?> getPinForUser(String userId) async {
    return await _storage.read(key: 'offline_pin_$userId');
  }
}
