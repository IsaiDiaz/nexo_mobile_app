// lib/application/search_professionals_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/auth_repository.dart'; // Usaremos AuthRepository para obtener profesionales

class SearchProfessionalsState {
  final List<pb.RecordModel>
  professionals; // Lista de RecordModel de professional_profile
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedCategory;

  SearchProfessionalsState({
    required this.professionals,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '', // Inicializado vacío
    this.selectedCategory = '', // Inicializado vacío
  });

  SearchProfessionalsState copyWith({
    List<pb.RecordModel>? professionals,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return SearchProfessionalsState(
      professionals: professionals ?? this.professionals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class SearchProfessionalsController
    extends StateNotifier<SearchProfessionalsState> {
  final AuthRepository
  _authRepository; // O ProfessionalProfileRepository si lo creas
  final Ref _ref;

  SearchProfessionalsController(this._authRepository, this._ref)
    : super(SearchProfessionalsState(professionals: [])) {
    // Al inicializar el controlador, cargamos los profesionales
    loadProfessionals();
  }

  Future<void> loadProfessionals({String? category, String? search}) async {
    // Usamos el 'link' para mantener el provider vivo si se cierra la pantalla
    // mientras la búsqueda está en curso.
    final link = _ref.keepAlive();
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final professionals = await _authRepository.getAllProfessionalProfiles(
        category: category,
        // Si necesitas un filtro de búsqueda directa en PocketBase, lo pasarías aquí
        // Por ahora, asumiremos que el filtrado por 'search' se hace en el cliente si es necesario.
      );

      // Si se proporciona un término de búsqueda, filtramos en el cliente
      // Esto es si tu backend no soporta búsqueda de texto completo en todos los campos.
      // Si PocketBase puede buscar por un término en múltiples campos, sería mejor en el repositorio.
      List<pb.RecordModel> filteredProfessionals = professionals;
      if (search != null && search.isNotEmpty) {
        final lowerCaseSearch = search.toLowerCase();
        filteredProfessionals = professionals.where((p) {
          // Accede a la información del usuario expandido para buscar por nombre
          final userName =
              p.get<String?>('expand.user.name')?.toLowerCase() ?? '';
          final businessName =
              p.get<String?>('business_name')?.toLowerCase() ?? '';
          final categoryName =
              p.get<String?>('category')?.toLowerCase() ??
              ''; // Si 'category' es un campo en professional_profile

          return userName.contains(lowerCaseSearch) ||
              businessName.contains(lowerCaseSearch) ||
              categoryName.contains(lowerCaseSearch);
        }).toList();
      }

      state = state.copyWith(
        isLoading: false,
        professionals: filteredProfessionals,
        searchQuery: search ?? state.searchQuery, // Actualiza el query
        selectedCategory:
            category ?? state.selectedCategory, // Actualiza la categoría
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    } finally {
      link.close();
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    // Recarga los profesionales con la nueva consulta (y la categoría actual)
    loadProfessionals(category: state.selectedCategory, search: query);
  }

  void updateSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    // Recarga los profesionales con la nueva categoría (y la consulta actual)
    loadProfessionals(category: category, search: state.searchQuery);
  }
}

final searchProfessionalsControllerProvider =
    StateNotifierProvider.autoDispose<
      SearchProfessionalsController,
      SearchProfessionalsState
    >((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return SearchProfessionalsController(authRepository, ref);
    });

final filteredProfessionalsProvider =
    Provider.autoDispose<List<pb.RecordModel>>((ref) {
      final searchState = ref.watch(searchProfessionalsControllerProvider);
      return searchState.professionals; // Ya están filtrados por el controller
    });
