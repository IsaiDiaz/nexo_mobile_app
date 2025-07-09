import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/chat_controller.dart';
import 'package:nexo/model/chat.dart';
import 'package:nexo/model/message.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/presentation/theme/app_colors.dart'; // ¡Añade esta importación!

class ChatDetailView extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatDetailView({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends ConsumerState<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  pb.RecordModel?
  _otherUserRecord; // Para almacenar el record del otro participante

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) {
        print(
          'ChatDetailView: Widget no montado en microtask, abortando _loadChatMessages.',
        );
        return;
      }
      _loadChatMessages();
      _loadOtherUserRecord();
    });

    // Scroll al final cuando se carguen los mensajes o se añadan nuevos
    // Usamos addPostFrameCallback para asegurar que el ListView esté renderizado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Segunda verificación por si acaso.

      if (_scrollController.hasClients) {
        // Verificación importante
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // Nuevo método para cargar el RecordModel del otro participante
  Future<void> _loadOtherUserRecord() async {
    final currentUser = ref.read(currentUserRecordProvider);
    if (currentUser == null) return;

    final otherParticipantId = widget.chat.getOtherParticipantId(
      currentUser.id,
    );

    // Intentar usar los records expandidos si están presentes
    pb.RecordModel? foundOtherUser;
    if (widget.chat.firstUserRecord?.id == otherParticipantId) {
      foundOtherUser = widget.chat.firstUserRecord;
    } else if (widget.chat.secondUserRecord?.id == otherParticipantId) {
      foundOtherUser = widget.chat.secondUserRecord;
    }

    // Si no se encontró el record expandido, o si fue null, intentar obtenerlo del repositorio
    if (foundOtherUser == null) {
      try {
        // Asumiendo que AuthRepository tiene un método para obtener un RecordModel de 'users' por ID
        // Si no tienes este método, necesitas agregarlo a AuthRepository
        foundOtherUser = await ref
            .read(authRepositoryProvider)
            .getUserById(otherParticipantId);
      } catch (e) {
        print('Error cargando el record del otro usuario: $e');
      }
    }

    // Actualizar el estado de la UI si el record se encontró
    // Solo si el widget todavía está montado
    if (mounted &&
        foundOtherUser != null &&
        _otherUserRecord?.id != foundOtherUser.id) {
      setState(() {
        _otherUserRecord = foundOtherUser;
      });
    }
  }

  @override
  void dispose() {
    // 1. Limpiar el currentSelectedChatProvider PRIMERO.
    // Esto es crítico para Riverpod: modifica el estado de un provider externo
    // antes de que `ref` se considere inválido por completo.
    ref.read(currentSelectedChatProvider.notifier).state = null;

    // 2. Cancelar la suscripción de mensajes del ChatController.
    // Llama a esto DESPUÉS de limpiar el chat seleccionado,
    // y antes de que el widget se desmonte completamente.
    // Esto previene que el ChatController intente notificar a un widget "defunct".
    // Aunque ref.read se usa aquí, suele ser menos problemático que la línea de arriba.
    ref.read(chatControllerProvider.notifier).unsubscribeFromMessages();

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose(); // super.dispose() siempre al final
  }

  Future<void> _loadChatMessages() async {
    await ref
        .read(chatControllerProvider.notifier)
        .loadAndSubscribeToChatMessages(widget.chat);

    if (mounted && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    await ref
        .read(chatControllerProvider.notifier)
        .sendMessage(widget.chat.id, messageContent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getSenderName(Message message, pb.RecordModel currentUser) {
    if (message.senderId == currentUser.id) {
      return 'Tú';
    } else {
      // Usar el nombre del RecordModel del sender si está expandido, si no, usar _otherUserRecord
      // PRIORIDAD: message.senderRecord (expandido en el mensaje) > _otherUserRecord (expandido en el chat)
      return message.senderRecord?.get<String>('name') ??
          _otherUserRecord?.get<String>('name') ??
          'Desconocido';
    }
  }

  String? _getSenderAvatarUrl(Message message, pb.RecordModel currentUser) {
    final pocketBase = ref.read(authRepositoryProvider).pocketBase;

    // Obtener el RecordModel del remitente directamente del mensaje si está expandido
    pb.RecordModel? senderUserRecord = message.senderRecord;

    // Si no está expandido en el mensaje, y es el otro usuario, usar _otherUserRecord
    if (senderUserRecord == null && message.senderId != currentUser.id) {
      senderUserRecord = _otherUserRecord;
    }

    // Si es el usuario actual, usar currentUser
    if (message.senderId == currentUser.id) {
      senderUserRecord = currentUser;
    }

    if (senderUserRecord != null) {
      // Usar get<String?> para acceder al campo 'avatar'
      final avatar = senderUserRecord.get<String?>('avatar');
      if (avatar != null && avatar.isNotEmpty) {
        return pocketBase.files.getURL(senderUserRecord, avatar).toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chatMessagesAsync = ref.watch(
      chatControllerProvider.select((state) => state.currentChatMessages),
    );
    final currentUser = ref.watch(currentUserRecordProvider);

    if (currentUser == null) {
      return const Center(child: Text('Error: Usuario no autenticado.'));
    }

    // Asegurarse de que _otherUserRecord esté cargado antes de usarlo en el título
    final otherUserName = _otherUserRecord?.get<String>('name') ?? 'Chat';
    final colorScheme = Theme.of(
      context,
    ).colorScheme; // <-- Obtener colorScheme aquí

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con $otherUserName'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: chatMessagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Envía el primer mensaje para iniciar la conversación.',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser.id;
                    final senderName = _getSenderName(message, currentUser);
                    final senderAvatarUrl = _getSenderAvatarUrl(
                      message,
                      currentUser,
                    );
                    final bubbleColor = isMe
                        ? Color(
                            0xFF0D2B3E,
                          ) // Fondo para tus mensajes (se mapea a LightAppColors.primaryBackground en claro, DarkAppColors.primaryBackground en oscuro)
                        : colorScheme.secondary.withOpacity(
                            0.8,
                          ); // Fondo para mensajes del otro (se mapea a Light/DarkAppColors.accentButton)

                    final textColor = isMe
                        ? Color(
                            0xFFFFFFFF,
                          ) // Texto sobre el color primary de la burbuja
                        : colorScheme
                              .onSecondary; // Texto sobre el color secondary de la burbuja

                    final secondaryTextColor = textColor.withOpacity(0.7);

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color:
                              bubbleColor, // Asumo que secondary es el color de las burbujas de "otros" (tu dorado/naranja)
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isMe) ...[
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: senderAvatarUrl != null
                                        ? NetworkImage(senderAvatarUrl)
                                        : null,
                                    child: senderAvatarUrl == null
                                        ? Text(
                                            senderName.isNotEmpty
                                                ? senderName[0].toUpperCase()
                                                : '?',
                                            // Color del texto del avatar si no hay imagen: NEGRO si la burbuja es clara, BLANCO si es oscura
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.black,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    senderName,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          // Color del nombre del remitente: NEGRO si la burbuja es clara, BLANCO si es oscura
                                          color: secondaryTextColor,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: senderAvatarUrl != null
                                        ? NetworkImage(senderAvatarUrl)
                                        : null,
                                    child: senderAvatarUrl == null
                                        ? Text(
                                            senderName.isNotEmpty
                                                ? senderName[0].toUpperCase()
                                                : '?',
                                            // Color del texto del avatar si no hay imagen (si soy yo, mi burbuja es primary, debería ser oscura)
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: textColor,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.content,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    // Color del contenido del mensaje: NEGRO si la burbuja es clara, BLANCO si es oscura
                                    color: textColor,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                // Color de la hora: NEGRO si la burbuja es clara, BLANCO si es oscura
                                color:
                                    secondaryTextColor, // Si no, es la oscura de otros
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Text('Error al cargar mensajes: ${e.toString()}'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ),
                    ),
                    onSubmitted: (_) =>
                        _sendMessage(), // Permite enviar con Enter
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
