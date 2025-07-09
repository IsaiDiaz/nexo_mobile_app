import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/chat_controller.dart';
import 'package:nexo/data/chat_repository.dart';
import 'package:nexo/model/chat.dart';
import 'package:nexo/application/auth_controller.dart'; // Para obtener el currentUserRecordProvider
import 'package:nexo/presentation/views/chat_detail_view.dart'; // Importar la vista de detalle
import 'package:nexo/presentation/theme/app_colors.dart'; // Para los colores
import 'package:pocketbase/pocketbase.dart' as pb;

class MessagesView extends ConsumerWidget {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    final chatController = ref.read(chatControllerProvider.notifier);
    final currentUser = ref.watch(
      currentUserRecordProvider,
    ); // Obtener el usuario actual para identificar al otro participante

    // Cargar los chats del usuario cuando la vista se inicialice
    // Se asegura de que se cargue una vez al entrar a esta vista.
    // Aunque ya se carga en el constructor del controlador, esto es útil si el controlador se descarta y recrea
    ref.listen<AsyncValue<List<Chat>>>(
      chatControllerProvider.select((state) => state.userChats),
      (previous, next) {
        next.when(
          data: (chats) {
            // Opcional: podrías hacer algo cuando los chats se carguen
          },
          loading: () {},
          error: (e, st) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al cargar chats: ${e.toString()}')),
            );
          },
        );
      },
    );

    if (currentUser == null) {
      return const Center(child: Text('Error: Usuario no autenticado.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mensajes'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: chatState.userChats.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Text(
                'No tienes chats aún. Puedes iniciar uno desde el perfil de un profesional.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              // Obtener el ID del otro participante en el chat
              final otherParticipantId = chat.getOtherParticipantId(
                currentUser.id,
              );

              // Buscar el RecordModel del otro participante para obtener su nombre/avatar
              // Esto es si ya lo expandiste en el ChatRepository.
              // Si no, tendrías que hacer una llamada adicional o confiar en el ID.
              pb.RecordModel? otherUserRecord;
              if (chat.firstUserRecord?.id == otherParticipantId) {
                otherUserRecord = chat.firstUserRecord;
              } else if (chat.secondUserRecord?.id == otherParticipantId) {
                otherUserRecord = chat.secondUserRecord;
              }

              final otherUserName =
                  otherUserRecord?.data['name'] as String? ??
                  'Usuario Desconocido';
              final otherUserAvatarUrl =
                  otherUserRecord?.data['avatar'] != null &&
                      otherUserRecord!.data['avatar'].isNotEmpty
                  ? ref
                        .read(chatRepositoryProvider)
                        .pocketBaseInstance // Usa el getter
                        .files
                        .getURL(otherUserRecord, otherUserRecord.data['avatar'])
                        .toString()
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                elevation: 2,
                color: Theme.of(context).brightness == Brightness.dark
                    ? DarkAppColors.cardAndInputFields
                    : LightAppColors.cardAndInputFields,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: otherUserAvatarUrl != null
                        ? NetworkImage(otherUserAvatarUrl)
                        : null,
                    child: otherUserAvatarUrl == null
                        ? Text(
                            otherUserName.isNotEmpty
                                ? otherUserName[0].toUpperCase()
                                : '?',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors
                                      .black, // Color para el texto de avatar
                                ),
                          )
                        : null,
                  ),
                  title: Text(
                    otherUserName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DarkAppColors.primaryText
                          : LightAppColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Chat ID: ${chat.id}', // Puedes mostrar el último mensaje aquí si lo tienes en el modelo Chat
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DarkAppColors.secondaryText
                          : LightAppColors.secondaryText,
                    ),
                  ),
                  onTap: () {
                    // Al tocar un chat, establece el chat seleccionado y navega a la vista de detalle
                    ref.read(currentSelectedChatProvider.notifier).state = chat;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatDetailView(chat: chat),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
      ),
    );
  }
}
