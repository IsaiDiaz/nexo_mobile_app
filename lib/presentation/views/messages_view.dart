import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/chat_controller.dart';
import 'package:nexo/data/chat_repository.dart';
import 'package:nexo/model/chat.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/presentation/views/chat_detail_view.dart';
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:pocketbase/pocketbase.dart' as pb;

class MessagesView extends ConsumerWidget {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    ref.read(chatControllerProvider.notifier);
    final currentUser = ref.watch(currentUserRecordProvider);

    ref.listen<AsyncValue<List<Chat>>>(
      chatControllerProvider.select((state) => state.userChats),
      (previous, next) {
        next.when(
          data: (chats) {},
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

              final otherParticipantId = chat.getOtherParticipantId(
                currentUser.id,
              );

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
                        .pocketBaseInstance
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
                                ?.copyWith(color: Colors.black),
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
                  // subtitle: Text(
                  //   'Chat ID: ${chat.id}',
                  //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //     color: Theme.of(context).brightness == Brightness.dark
                  //         ? DarkAppColors.secondaryText
                  //         : LightAppColors.secondaryText,
                  //   ),
                  // ),
                  onTap: () {
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
