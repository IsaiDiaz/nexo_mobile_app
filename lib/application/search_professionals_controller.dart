import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/auth_repository.dart';

class SearchProfessionalsState {
  final List<pb.RecordModel> professionals;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedCategory;

  SearchProfessionalsState({
    required this.professionals,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategory = '',
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
  final AuthRepository _authRepository;
  final Ref _ref;

  SearchProfessionalsController(this._authRepository, this._ref)
    : super(SearchProfessionalsState(professionals: [])) {
    loadProfessionals();
  }

  Future<void> loadProfessionals({String? category, String? search}) async {
    final link = _ref.keepAlive();
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final professionals = await _authRepository.getAllProfessionalProfiles(
        category: category,
      );

      List<pb.RecordModel> filteredProfessionals = professionals;
      if (search != null && search.isNotEmpty) {
        final lowerCaseSearch = search.toLowerCase();
        filteredProfessionals = professionals.where((p) {
          final userName =
              p.get<String?>('expand.user.name')?.toLowerCase() ?? '';
          final businessName =
              p.get<String?>('business_name')?.toLowerCase() ?? '';
          final categoryName = p.get<String?>('category')?.toLowerCase() ?? '';

          return userName.contains(lowerCaseSearch) ||
              businessName.contains(lowerCaseSearch) ||
              categoryName.contains(lowerCaseSearch);
        }).toList();
      }

      state = state.copyWith(
        isLoading: false,
        professionals: filteredProfessionals,
        searchQuery: search ?? state.searchQuery,
        selectedCategory: category ?? state.selectedCategory,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    } finally {
      link.close();
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadProfessionals(category: state.selectedCategory, search: query);
  }

  void updateSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
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
      return searchState.professionals;
    });
