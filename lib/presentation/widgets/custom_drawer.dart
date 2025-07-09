import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/presentation/pages/home_page.dart';
import 'package:nexo/presentation/theme/app_colors.dart';

class CustomDrawer extends ConsumerWidget {
  final pb.RecordModel currentUser;
  final UserRole? activeRole;
  final List<UserRole> availableRoles;
  final ValueChanged<UserRole> onRoleSwitch;
  final ValueChanged<HomeSection> onSectionSelected;

  const CustomDrawer({
    super.key,
    required this.currentUser,
    required this.activeRole,
    required this.availableRoles,
    required this.onRoleSwitch,
    required this.onSectionSelected,
  });

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
    final accentColor = isDarkMode
        ? DarkAppColors.accentButton
        : LightAppColors.accentButton;
    final drawerBackgroundColor = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;

    final hasBothRoles = availableRoles.length > 1;

    final userName = currentUser.data['name'] as String? ?? 'Usuario';

    final pocketBase = ref.read(authRepositoryProvider).pocketBase;

    final avatarUrl =
        currentUser.data['avatar'] != null &&
            currentUser.data['avatar'].isNotEmpty
        ? pocketBase.files
              .getURL(currentUser, currentUser.data['avatar'])
              .toString()
        : null;

    return Drawer(
      backgroundColor: drawerBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              userName,
              style: theme.textTheme.titleLarge?.copyWith(
                color: primaryTextColor,
              ),
            ),
            accountEmail: Text(
              currentUser.data['email'] as String? ?? 'email@example.com',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: accentColor,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.black,
                      ),
                    )
                  : null,
            ),
            decoration: BoxDecoration(color: theme.appBarTheme.backgroundColor),
          ),
          // Opciones específicas del rol ACTIVO
          if (activeRole == UserRole.client) ...[
            _buildDrawerItem(
              context,
              ref,
              HomeSection.searchProfessionals,
              'Buscar Profesionales',
              Icons.search,
            ),
            _buildDrawerItem(
              context,
              ref,
              HomeSection.clientAppointments,
              'Mis Citas',
              Icons.calendar_today,
            ),
            _buildDrawerItem(
              context,
              ref,
              HomeSection.messages, // Aquí se enlaza con la nueva sección
              'Mensajes',
              Icons.message,
            ),
            _buildDrawerItem(
              context,
              ref,
              HomeSection.professionalAnnouncements,
              'Anuncios',
              Icons.announcement,
            ),
          ] else if (activeRole == UserRole.professional) ...[
            _buildDrawerItem(
              context,
              ref,
              HomeSection.professionalAppointments,
              'Mis Citas',
              Icons.calendar_month,
            ),
            _buildDrawerItem(
              context,
              ref,
              HomeSection.messages, // Aquí se enlaza con la nueva sección
              'Mensajes',
              Icons.message,
            ),
            _buildDrawerItem(
              context,
              ref,
              HomeSection.scheduleManagement,
              'Gestionar Horarios',
              Icons.schedule,
            ),
            _buildDrawerItem(
              context,
              ref,
              HomeSection.professionalNotifications,
              'Notificaciones',
              Icons.notifications,
            ),
          ],
          const Divider(),
          // Opciones compartidas por ambos roles
          _buildDrawerItem(
            context,
            ref,
            HomeSection.editPersonalInfo,
            'Editar Perfil Personal',
            Icons.person,
          ),
          if (availableRoles.contains(UserRole.professional))
            _buildDrawerItem(
              context,
              ref,
              HomeSection.editProfessionalInfo,
              'Editar Perfil Profesional',
              Icons.business,
            ),
          // Opción para cambiar de rol si tiene ambos
          if (hasBothRoles)
            ListTile(
              leading: Icon(Icons.swap_horiz, color: secondaryTextColor),
              title: Text(
                activeRole == UserRole.client
                    ? 'Cambiar a Vista Profesional'
                    : 'Cambiar a Vista Cliente',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: primaryTextColor,
                ),
              ),
              onTap: () {
                final newRole = activeRole == UserRole.client
                    ? UserRole.professional
                    : UserRole.client;
                onRoleSwitch(newRole);
              },
            ),
          // Opción para obtener el rol que le falta
          if (!hasBothRoles)
            ListTile(
              leading: Icon(
                Icons.add_circle_outline,
                color: secondaryTextColor,
              ),
              title: Text(
                activeRole == UserRole.client
                    ? 'Conviértete en Profesional'
                    : 'Conviértete en Cliente',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: primaryTextColor,
                ),
              ),
              onTap: () {
                onSectionSelected(
                  HomeSection.getOtherRole,
                ); // Llama a la sección para manejar esta lógica
              },
            ),
          _buildDrawerItem(
            context,
            ref,
            HomeSection.settings,
            'Configuración',
            Icons.settings,
          ),
          ListTile(
            leading: Icon(Icons.logout, color: secondaryTextColor),
            title: Text(
              'Cerrar Sesión',
              style: theme.textTheme.titleMedium?.copyWith(
                color: primaryTextColor,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop(); // Cierra el drawer antes de logout
              await ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    WidgetRef ref,
    HomeSection section,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final secondaryTextColor = isDarkMode
        ? DarkAppColors.secondaryText
        : LightAppColors.secondaryText;
    final accentColor = isDarkMode
        ? DarkAppColors.accentButton
        : LightAppColors.accentButton;

    final isActive = ref.watch(homeSectionProvider) == section;

    return ListTile(
      leading: Icon(icon, color: isActive ? accentColor : secondaryTextColor),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isActive ? accentColor : primaryTextColor,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => onSectionSelected(section),
    );
  }
}
