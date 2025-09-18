import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/application/chat_controller.dart';
import 'package:nexo/model/chat.dart';
import 'package:nexo/model/message.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:pocketbase/pocketbase.dart' as pb;

class ChatDetailView extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatDetailView({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends ConsumerState<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  pb.RecordModel? _otherUserRecord;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _loadOtherUserRecord() async {
    final currentUser = ref.read(currentUserRecordProvider);
    if (currentUser == null) return;

    final otherParticipantId = widget.chat.getOtherParticipantId(
      currentUser.id,
    );

    pb.RecordModel? foundOtherUser;
    if (widget.chat.firstUserRecord?.id == otherParticipantId) {
      foundOtherUser = widget.chat.firstUserRecord;
    } else if (widget.chat.secondUserRecord?.id == otherParticipantId) {
      foundOtherUser = widget.chat.secondUserRecord;
    }

    if (foundOtherUser == null) {
      try {
        foundOtherUser = await ref
            .read(authRepositoryProvider)
            .getUserById(otherParticipantId);
      } catch (e) {
        print('Error cargando el record del otro usuario: $e');
      }
    }

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
    ref.read(currentSelectedChatProvider.notifier).state = null;
    ref.read(chatControllerProvider.notifier).unsubscribeFromMessages();

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
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
      return message.senderRecord?.get<String>('name') ??
          _otherUserRecord?.get<String>('name') ??
          'Desconocido';
    }
  }

  String? _getSenderAvatarUrl(Message message, pb.RecordModel currentUser) {
    final pocketBase = ref.read(authRepositoryProvider).pocketBase;

    pb.RecordModel? senderUserRecord = message.senderRecord;

    if (senderUserRecord == null && message.senderId != currentUser.id) {
      senderUserRecord = _otherUserRecord;
    }

    if (message.senderId == currentUser.id) {
      senderUserRecord = currentUser;
    }

    if (senderUserRecord != null) {
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

    final otherUserName = _otherUserRecord?.get<String>('name') ?? 'Chat';
    final colorScheme = Theme.of(context).colorScheme;

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
                        ? Color(0xFF0D2B3E)
                        : colorScheme.secondary.withOpacity(0.8);

                    final textColor = isMe
                        ? Color(0xFFFFFFFF)
                        : colorScheme.onSecondary;

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
                          color: bubbleColor,
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
                                  ?.copyWith(color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: secondaryTextColor,
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
                    onSubmitted: (_) => _sendMessage(),
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
