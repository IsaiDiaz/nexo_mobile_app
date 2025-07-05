import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:nexo/presentation/views/schedule_management_view.dart';
import 'package:nexo/presentation/views/search_professionals_view.dart';
import 'package:nexo/presentation/widgets/custom_drawer.dart';

enum HomeSection {
  searchProfessionals,
  clientAppointments,
  professionalAnnouncements,
  professionalAppointments,
  scheduleManagement,
  professionalNotifications,
  editPersonalInfo,
  editProfessionalInfo,
  settings,
  getOtherRole,
}

final homeSectionProvider = StateProvider<HomeSection>((ref) {
  final activeRole = ref.watch(activeRoleProvider);
  if (activeRole == UserRole.client) {
    return HomeSection.searchProfessionals;
  } else if (activeRole == UserRole.professional) {
    return HomeSection.professionalAppointments;
  }
  return HomeSection.searchProfessionals;
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final currentUser = ref.watch(currentUserRecordProvider);
    final activeRole = ref.watch(activeRoleProvider);
    final availableRoles = ref.watch(availableUserRolesProvider);
    final currentSection = ref.watch(homeSectionProvider);

    if (authState == AuthState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState != AuthState.authenticated || currentUser == null) {
      return const Center(
        child: Text('Error: No autenticado o usuario no encontrado.'),
      );
    }

    String appBarTitle = 'Nexo';
    if (activeRole == UserRole.client) {
      appBarTitle = 'Nexo (Cliente)';
    } else if (activeRole == UserRole.professional) {
      appBarTitle = 'Nexo (Profesional)';
    }

    Widget _buildBody(HomeSection section) {
      switch (section) {
        case HomeSection.searchProfessionals:
          return const SearchProfessionalsView();
        case HomeSection.clientAppointments:
          return const Center(
            child: Text('Citas de Cliente (Próximas/Pendientes)'),
          ); // TODO: Implementar
        case HomeSection.professionalAnnouncements:
          return const Center(
            child: Text('Anuncios de Profesionales'),
          ); // TODO: Implementar
        case HomeSection.professionalAppointments:
          return const Center(
            child: Text('Citas de Profesional (Próximas/Pendientes)'),
          ); // TODO: Implementar
        case HomeSection.scheduleManagement:
          return const Center(
            child: ScheduleManagementView(),
          ); // TODO: Implementar
        case HomeSection.professionalNotifications:
          return const Center(
            child: Text('Notificaciones Profesionales'),
          ); // TODO: Implementar
        case HomeSection.editPersonalInfo:
          return const Center(
            child: Text('Editar Información Personal'),
          ); // TODO: Implementar
        case HomeSection.editProfessionalInfo:
          return const Center(
            child: Text('Editar Información Profesional'),
          ); // TODO: Implementar
        case HomeSection.settings:
          return const Center(
            child: Text('Configuración General'),
          ); // TODO: Implementar
        case HomeSection.getOtherRole:
          return const Center(
            child: Text('Obtener el Otro Rol'),
          ); // TODO: Implementar
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      drawer: CustomDrawer(
        currentUser: currentUser,
        activeRole: activeRole,
        availableRoles: availableRoles,
        onRoleSwitch: (role) {
          ref.read(activeRoleProvider.notifier).state = role;
          ref.read(homeSectionProvider.notifier).state = role == UserRole.client
              ? HomeSection.searchProfessionals
              : HomeSection.professionalAppointments;
          Navigator.of(context).pop();
        },
        onSectionSelected: (section) {
          ref.read(homeSectionProvider.notifier).state = section;
          Navigator.of(context).pop();
        },
      ),
      body: _buildBody(currentSection),
    );
  }
}
