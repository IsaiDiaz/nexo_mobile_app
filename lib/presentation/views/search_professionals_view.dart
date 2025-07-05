import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

class SearchProfessionalsView extends ConsumerWidget {
  const SearchProfessionalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;

    return Center(
      child: Text(
        'Aquí puedes buscar profesionales',
        style: theme.textTheme.headlineSmall?.copyWith(color: primaryTextColor),
      ),
    );
  }
}
