// lib/data/auth_repository.dart

import 'package:flutter/material.dart';
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
    required role,
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
              'avatar',
              await avatarFile.readAsBytes(),
              filename: avatarFile.path.split('/').last,
            ),
          );
        }
      }

      final userRecord = await _pb
          .collection('users')
          .create(body: body, files: filesToUpload);

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
              'coordinate': {'lat': coordinateLat, 'lon': coordinateLon},
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

  Future<pb.RecordModel?> getPersonProfile(String userId) async {
    try {
      final result = await _pb
          .collection('person')
          .getFirstListItem('user="$userId"');
      return result;
    } on pb.ClientException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (e) {
      print('Error al obtener perfil personal: $e');
      return null;
    }
  }

  Future<pb.RecordModel?> getProfessionalProfile(String userId) async {
    try {
      final result = await _pb
          .collection('professional_profile')
          .getFirstListItem('user="$userId"');
      print("Professional profile fetched: ${result.toJson()}");
      return result;
    } on pb.ClientException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (e) {
      print('Error al obtener perfil profesional: $e');
      return null;
    }
  }

  Future<List<pb.RecordModel>> getAllProfessionalProfiles({
    String? category,
  }) async {
    try {
      // expand 'user' para obtener el nombre, email, etc. del usuario autenticado asociado
      // expand 'available_schedules' si quieres mostrar sus horarios en la búsqueda
      final records = await pocketBase
          .collection('professional_profile')
          .getFullList(
            filter: category != null && category.isNotEmpty
                ? 'category = "$category"' // Ejemplo de filtro por especialización (si es campo texto)
                : '',
            expand: 'user', // <--- Importante: expandir usuario y horarios
          );

      print(records);
      return records;
    } on pb.ClientException catch (e) {
      print(
        'PocketBase ClientException in getAllProfessionalProfiles: ${e.response}',
      );
      throw Exception(
        'Error al obtener perfiles profesionales: ${e.response['message']}',
      );
    } catch (e) {
      print('Error inesperado en getAllProfessionalProfiles: $e');
      throw Exception('Error inesperado al obtener perfiles profesionales: $e');
    }
  }

  Future<void> updatePersonProfile({
    required String recordId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? identificationNumber,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (identificationNumber != null) {
        body['identification_number'] = identificationNumber;
      }

      await _pb.collection('person').update(recordId, body: body);
    } on pb.ClientException catch (e) {
      throw Exception(
        'Error al actualizar perfil personal: ${e.response['message']}',
      );
    } catch (e) {
      throw Exception(
        'Ocurrió un error inesperado al actualizar perfil personal: $e',
      );
    }
  }

  Future<void> updateProfessionalProfile({
    required String recordId,
    double? hourlyRate,
    String? address,
    String? description,
    String? businessName,
    double? coordinateLat,
    double? coordinateLon,
    String? category,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (hourlyRate != null) body['hourly_rate'] = hourlyRate;
      if (address != null) body['address'] = address;
      if (description != null) body['description'] = description;
      if (businessName != null) body['business_name'] = businessName;
      if (coordinateLat != null && coordinateLon != null) {
        body['coordinate'] = {'lat': coordinateLat, 'lon': coordinateLon};
      }
      if (category != null) body['category'] = category;

      await _pb.collection('professional_profile').update(recordId, body: body);
    } on pb.ClientException catch (e) {
      throw Exception(
        'Error al actualizar perfil profesional: ${e.response['message']}',
      );
    } catch (e) {
      throw Exception(
        'Ocurrió un error inesperado al actualizar perfil profesional: $e',
      );
    }
  }

  Future<void> addRoleToUser(String userId, UserRole newRole) async {
    try {
      final user = await _pb.collection('users').getOne(userId);
      List<String> currentRoles = (user.data['role'] as List).cast<String>();

      if (!currentRoles.contains(newRole.name.toUpperCase())) {
        currentRoles.add(newRole.name.toUpperCase());
        await _pb
            .collection('users')
            .update(userId, body: {'role': currentRoles});
      }
    } on pb.ClientException catch (e) {
      throw Exception(
        'Error al añadir rol al usuario: ${e.response['message']}',
      );
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al añadir rol: $e');
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
