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

    Widget getRegistrationPage(RegistrationStep step) {
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

    List<Page> buildPages() {
      if (isAuthenticated) {
        return [const MaterialPage(child: HomePage())];
      }

      switch (registrationState.currentStep) {
        case RegistrationStep.none:
          return [const MaterialPage(child: LoginPage())];
        case RegistrationStep.roleSelection:
          return [const MaterialPage(child: RoleSelectionPage())];
        case RegistrationStep.userRegistration:
          return [MaterialPage(child: UserRegistrationPage())];
        case RegistrationStep.personDetails:
          return [MaterialPage(child: PersonDetailsPage())];
        case RegistrationStep.professionalProfile:
          return [const MaterialPage(child: ProfessionalProfilePage())];
        case RegistrationStep.completed:
          return [const MaterialPage(child: LoginPage())];
      }
    }

    final currentPage = isAuthenticated
        ? const HomePage()
        : getRegistrationPage(registrationState.currentStep);

    return MaterialApp(
      title: 'Nexo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: Navigator(
        pages: buildPages(),
        onDidRemovePage: (page) {
          debugPrint("Página eliminada: ${page.key}");
        },
      ),
    );
  }
}
