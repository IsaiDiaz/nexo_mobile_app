// lib/data/auth_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:nexo/model/registration_data.dart';

class AuthRepository {
  late final pb.PocketBase _pb;

  AuthRepository() {
    _pb = pb.PocketBase(
      dotenv.env['POCKETBASE_URL'] ?? "http://127.0.0.1:8090",
    );
  }

  pb.PocketBase get pocketBase => _pb;

  bool get isAuthenticated => _pb.authStore.isValid;
  pb.RecordModel? get currentUser => _pb.authStore.record;

  Future<void> signIn(String identity, String password) async {
    try {
      await _pb.collection('users').authWithPassword(identity, password);
    } on pb.ClientException catch (e) {
      throw Exception('Error de autenticación: ${e.response['message']}');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  Future<pb.RecordModel?> signUpWithProfile({
    required String email,
    required String password,
    required String username,
    required String role,
    String? avatarPath,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': username,
        'role': role,
      };

      List<http.MultipartFile> filesToUpload = [];

      if (avatarPath != null && avatarPath.isNotEmpty) {
        final avatarFile = File(avatarPath);
        if (await avatarFile.exists()) {
          filesToUpload.add(
            http.MultipartFile.fromBytes(
              // <--- Usa el alias 'http.'
              'avatar', // Nombre del campo 'file' en PocketBase
              await avatarFile.readAsBytes(),
              filename: avatarFile.path.split('/').last,
            ),
          );
        }
      }

      // Crear el usuario
      final userRecord = await _pb
          .collection('users')
          .create(
            body: body,
            files: filesToUpload, // Pasa la lista de MultipartFile
          );

      await signIn(email, password);

      return userRecord;
    } on pb.ClientException catch (e) {
      print('Error en signUpWithProfile (PB ClientException): ${e.response}');
      throw Exception('Error al registrar usuario: ${e.response['message']}');
    } catch (e) {
      print('Error en signUpWithProfile (General Exception): $e');
      throw Exception('Ocurrió un error inesperado durante el registro: $e');
    }
  }

  // Nuevo método para crear el perfil 'person'
  Future<void> createPersonProfile({
    required String userId,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    required String identificationNumber,
  }) async {
    try {
      await _pb
          .collection('person')
          .create(
            body: {
              'user': userId,
              'name': firstName,
              'last_name': lastName,
              'phone_number': phoneNumber,
              'identification_number': identificationNumber,
            },
          );
    } on pb.ClientException catch (e) {
      throw Exception(
        'Error al crear perfil personal: ${e.response['message']}',
      );
    } catch (e) {
      throw Exception(
        'Ocurrió un error inesperado al crear perfil personal: $e',
      );
    }
  }

  // Nuevo método para crear el perfil 'professional_profile'
  Future<void> createProfessionalProfile({
    required String userId,
    required double hourlyRate,
    required String address,
    required String description,
    required String businessName,
    required double coordinateLat,
    required double coordinateLon,
    required String category,
  }) async {
    try {
      await _pb
          .collection('professional_profile')
          .create(
            body: {
              'user': userId,
              'hourly_rate': hourlyRate,
              'address': address,
              'description': description,
              'business_name': businessName,
              'coordinate': {
                'lat': coordinateLat,
                'lon': coordinateLon,
              }, // Formato para GeoPoint
              'category': category,
            },
          );
    } on pb.ClientException catch (e) {
      throw Exception(
        'Error al crear perfil profesional: ${e.response['message']}',
      );
    } catch (e) {
      throw Exception(
        'Ocurrió un error inesperado al crear perfil profesional: $e',
      );
    }
  }

  Future<void> signOut() async {
    _pb.authStore.clear();
  }

  Future<List<pb.RecordModel>> getUsers() async {
    try {
      final result = await _pb
          .collection('users')
          .getList(page: 1, perPage: 50);
      return result.items;
    } on pb.ClientException catch (e) {
      throw Exception('Error al obtener usuarios: ${e.response['message']}');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al obtener usuarios: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = AuthRepository();
  return repository;
});
