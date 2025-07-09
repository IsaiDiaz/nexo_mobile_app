import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/registration_controller.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final primaryBackgroundColor = isDarkMode
        ? DarkAppColors.primaryBackground
        : LightAppColors.primaryBackground;
    final accentButtonColor = isDarkMode
        ? DarkAppColors.accentButton
        : LightAppColors.accentButton;
    final cardAndInputFieldsColor = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Selecciona tu Rol',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Cómo te gustaría unirte a Nexo?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildRoleButton(
                context,
                ref,
                'Soy Profesional',
                UserRole.professional,
                Icons.business_center,
                accentButtonColor,
                cardAndInputFieldsColor,
                primaryTextColor,
              ),
              const SizedBox(height: 20),
              _buildRoleButton(
                context,
                ref,
                'Soy Cliente',
                UserRole.client,
                Icons.people,
                accentButtonColor,
                cardAndInputFieldsColor,
                primaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    WidgetRef ref,
    String text,
    UserRole role,
    IconData icon,
    Color accentColor,
    Color cardColor,
    Color textColor,
  ) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          ref.read(registrationControllerProvider.notifier).selectRole(role);
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
          child: Row(
            children: [
              Icon(icon, size: 30, color: accentColor),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: textColor.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
