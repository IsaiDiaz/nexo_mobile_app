import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/search_professionals_controller.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/presentation/widgets/professional_card.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/presentation/widgets/professional_details_sheet.dart';

class SearchProfessionalsView extends ConsumerWidget {
  const SearchProfessionalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final secondaryTextColor = isDarkMode
        ? DarkAppColors.secondaryText
        : LightAppColors.secondaryText;
    final cardAndInputColor = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;

    final searchState = ref.watch(searchProfessionalsControllerProvider);
    final searchController = ref.read(
      searchProfessionalsControllerProvider.notifier,
    );

    final List<String> categories = [
      '',
      'Salud',
      'Legal',
      'Tecnología',
      'Asistencia',
      'Otro',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: TextEditingController(
                  text: searchState.searchQuery,
                ),
                onChanged: (query) {
                  searchController.updateSearchQuery(query);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, negocio o categoría...',
                  hintStyle: TextStyle(
                    color: secondaryTextColor.withOpacity(0.7),
                  ),
                  prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cardAndInputColor,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                ),
                style: TextStyle(color: primaryTextColor),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: searchState.selectedCategory.isEmpty
                    ? ''
                    : searchState.selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Filtrar por categoría',
                  labelStyle: TextStyle(color: secondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cardAndInputColor,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                ),
                dropdownColor: cardAndInputColor,
                style: TextStyle(color: primaryTextColor),
                icon: Icon(Icons.arrow_drop_down, color: secondaryTextColor),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category.isEmpty ? 'Todas las categorías' : category,
                      style: TextStyle(color: primaryTextColor),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  searchController.updateSelectedCategory(value ?? '');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (searchState.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Buscando profesionales...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (searchState.errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${searchState.errorMessage}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              }

              if (searchState.professionals.isEmpty) {
                return Center(
                  child: Text(
                    'No se encontraron profesionales.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: searchState.professionals.length,
                itemBuilder: (context, index) {
                  final professionalProfile = searchState.professionals[index];
                  return ProfessionalCard(
                    professionalProfile: professionalProfile,
                    onViewDetails: (profile) {
                      _showProfessionalDetails(context, ref, profile);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showProfessionalDetails(
    BuildContext context,
    WidgetRef ref,
    pb.RecordModel professionalProfile,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ProfessionalDetailsSheet(
          professionalProfile: professionalProfile,
        );
      },
    );
  }
}
