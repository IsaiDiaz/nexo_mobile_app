import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/presentation/views/client_appointments_view.dart';
import 'package:nexo/presentation/views/professional_appointments_view.dart';
import 'package:nexo/presentation/views/schedule_management_view.dart';
import 'package:nexo/presentation/views/search_professionals_view.dart';
import 'package:nexo/presentation/widgets/custom_drawer.dart';
import 'package:nexo/presentation/views/messages_view.dart';

//Comentario para probar ci/cd y evidencia de ejecuciones automaticas

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
  messages,
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

    Widget buildBody(HomeSection section) {
      switch (section) {
        case HomeSection.searchProfessionals:
          return const SearchProfessionalsView();
        case HomeSection.clientAppointments:
          return const ClientAppointmentsView();
        case HomeSection.professionalAnnouncements:
          return const Center(child: Text('Anuncios de Profesionales'));
        case HomeSection.professionalAppointments:
          return ProfessionalAppointmentsView();
        case HomeSection.scheduleManagement:
          return const Center(child: ScheduleManagementView());
        case HomeSection.professionalNotifications:
          return const Center(child: Text('Notificaciones Profesionales'));
        case HomeSection.editPersonalInfo:
          return const Center(child: Text('Editar Información Personal'));
        case HomeSection.editProfessionalInfo:
          return const Center(child: Text('Editar Información Profesional'));
        case HomeSection.settings:
          return const Center(child: Text('Configuración General'));
        case HomeSection.getOtherRole:
          return const Center(child: Text('Obtener el Otro Rol'));
        case HomeSection.messages:
          return const MessagesView();
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
      body: buildBody(currentSection),
    );
  }
}
