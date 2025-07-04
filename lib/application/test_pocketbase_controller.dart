import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/data/auth_repository.dart'; // Importa tu AuthRepository
import 'package:pocketbase/pocketbase.dart'; // Para RecordModel

// Estado para la respuesta de la API
class TestPocketbaseState {
  final String message;
  final bool isLoading;

  TestPocketbaseState({
    this.message = 'Presiona el botón para obtener usuarios',
    this.isLoading = false,
  });

  TestPocketbaseState copyWith({String? message, bool? isLoading}) {
    return TestPocketbaseState(
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// StateNotifier para gestionar el estado de la llamada a la API
class TestPocketbaseNotifier extends StateNotifier<TestPocketbaseState> {
  final AuthRepository _authRepository;

  TestPocketbaseNotifier(this._authRepository) : super(TestPocketbaseState());

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, message: 'Obteniendo usuarios...');
    try {
      final List<RecordModel> users = await _authRepository.getUsers();
      String userNames = users
          .map((user) => user.data['email'] ?? user.id)
          .join(', ');
      if (userNames.isEmpty) {
        userNames = 'No se encontraron usuarios.';
      }
      state = state.copyWith(
        isLoading: false,
        message: 'Usuarios obtenidos: $userNames',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, message: 'Error: $e');
    }
  }
}

// Provider para TestPocketbaseNotifier
final testPocketbaseControllerProvider =
    StateNotifierProvider<TestPocketbaseNotifier, TestPocketbaseState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return TestPocketbaseNotifier(authRepository);
    });
