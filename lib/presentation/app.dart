import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/application/registration_controller.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/presentation/pages/login_page.dart';
import 'package:nexo/presentation/pages/home_page.dart';
import 'package:nexo/presentation/pages/registration/role_selection_page.dart';
import 'package:nexo/presentation/pages/registration/user_registration_page.dart';
import 'package:nexo/presentation/pages/registration/person_details_page.dart';
import 'package:nexo/presentation/pages/registration/professional_profile_page.dart';
import 'package:nexo/presentation/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authStatusProvider);
    final registrationState = ref.watch(registrationControllerProvider);

    Widget _getRegistrationPage(RegistrationStep step) {
      switch (step) {
        case RegistrationStep.none:
          return const LoginPage();
        case RegistrationStep.roleSelection:
          return const RoleSelectionPage();
        case RegistrationStep.userRegistration:
          return UserRegistrationPage();
        case RegistrationStep.personDetails:
          return PersonDetailsPage();
        case RegistrationStep.professionalProfile:
          return const ProfessionalProfilePage();
        case RegistrationStep.completed:
          return const LoginPage();
      }
    }

    Widget currentScreen;
    if (isAuthenticated) {
      currentScreen = const HomePage();
    } else {
      if (registrationState.currentStep != RegistrationStep.completed &&
          registrationState.currentStep != RegistrationStep.roleSelection) {
        currentScreen = _getRegistrationPage(registrationState.currentStep);
      } else if (registrationState.currentStep ==
          RegistrationStep.roleSelection) {
        currentScreen = const RoleSelectionPage();
      } else {
        currentScreen = const LoginPage();
      }
    }

    return MaterialApp(
      title: 'Nexo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: currentScreen,
    );
  }
}
