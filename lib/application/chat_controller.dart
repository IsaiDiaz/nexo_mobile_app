import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/data/chat_repository.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/application/auth_controller.dart';
import 'package:nexo/model/chat.dart';
import 'package:nexo/model/message.dart';
import 'dart:async';

class ChatState {
  final AsyncValue<List<Chat>> userChats;
  final AsyncValue<List<Message>> currentChatMessages;
  final bool isLoading;
  final String? errorMessage;

  ChatState({
    required this.userChats,
    required this.currentChatMessages,
    this.isLoading = false,
    this.errorMessage,
  });

  ChatState copyWith({
    AsyncValue<List<Chat>>? userChats,
    AsyncValue<List<Message>>? currentChatMessages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatState(
      userChats: userChats ?? this.userChats,
      currentChatMessages: currentChatMessages ?? this.currentChatMessages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final currentSelectedChatProvider = StateProvider<Chat?>((ref) => null);

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) {
    final chatRepository = ref.read(chatRepositoryProvider);
    final currentUserId = ref.watch(
      currentUserRecordProvider.select((user) => user?.id),
    );
    return ChatController(chatRepository, currentUserId, ref);
  },
);

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _chatRepository;
  final String? _currentUserId;
  final Ref _ref;
  StreamSubscription<Message>? _messageSubscription;

  ChatController(this._chatRepository, this._currentUserId, this._ref)
    : super(
        ChatState(
          userChats: const AsyncValue.loading(),
          currentChatMessages: const AsyncValue.data([]),
        ),
      ) {
    if (_currentUserId != null) {
      loadUserChats();
    }

    _ref.onDispose(() {
      print('ChatController: Disposing, canceling message subscription.');
      _messageSubscription?.cancel();
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadUserChats() async {
    if (_currentUserId == null) {
      state = state.copyWith(
        userChats: AsyncValue.error('User not logged in', StackTrace.current),
      );
      return;
    }
    state = state.copyWith(
      userChats: const AsyncValue.loading(),
      errorMessage: null,
    );
    try {
      final chats = await _chatRepository.getUserChats(_currentUserId);
      state = state.copyWith(userChats: AsyncValue.data(chats));
    } catch (e, st) {
      state = state.copyWith(
        userChats: AsyncValue.error(e, st),
        errorMessage: e.toString(),
      );
    }
  }

  Future<Chat?> initiateChatWithProfessional(String professionalId) async {
    if (_currentUserId == null) {
      state = state.copyWith(errorMessage: 'User not logged in');
      return null;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final chat = await _chatRepository.findOrCreateChat(
        _currentUserId,
        professionalId,
      );
      await loadUserChats();
      _ref.read(currentSelectedChatProvider.notifier).state = chat;
      state = state.copyWith(isLoading: false);
      return chat;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> loadAndSubscribeToChatMessages(Chat chat) async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    print('ChatController: Cancelada suscripción anterior si existía.');

    state = state.copyWith(currentChatMessages: const AsyncValue.loading());
    try {
      final messages = await _chatRepository.getChatMessages(chat.id);
      state = state.copyWith(currentChatMessages: AsyncValue.data(messages));
      print('ChatController: Mensajes históricos cargados: ${messages.length}');
    } catch (e, st) {
      print('ChatController: Error cargando mensajes históricos: $e');
      state = state.copyWith(currentChatMessages: AsyncValue.error(e, st));
      return;
    }

    print(
      'ChatController: Estableciendo nueva suscripción para chat ${chat.id}',
    );
    _messageSubscription = _chatRepository
        .subscribeToChatMessages(chat.id)
        .listen(
          (newMessage) {
            if (state.currentChatMessages is AsyncData<List<Message>>) {
              final currentMessages = state.currentChatMessages.value ?? [];
              final updatedMessages = List<Message>.from(currentMessages);
              final existingIndex = updatedMessages.indexWhere(
                (msg) => msg.id == newMessage.id,
              );

              if (existingIndex != -1) {
                updatedMessages[existingIndex] = newMessage;
              } else {
                updatedMessages.add(newMessage);
              }
              updatedMessages.sort(
                (a, b) => a.createdAt.compareTo(b.createdAt),
              );

              state = state.copyWith(
                currentChatMessages: AsyncValue.data(updatedMessages),
              );
              print(
                'ChatController: Mensaje en tiempo real recibido/actualizado. Total: ${updatedMessages.length}',
              );
            } else {
              print(
                'ChatController: Recibido mensaje en tiempo real, pero el estado no es AsyncData. Re-cargando.',
              );
              _chatRepository
                  .getChatMessages(chat.id)
                  .then((messages) {
                    state = state.copyWith(
                      currentChatMessages: AsyncValue.data(messages),
                    );
                  })
                  .catchError((e) {
                    print(
                      'ChatController: Error al recargar mensajes después de evento de suscripción: $e',
                    );
                  });
            }
          },
          onError: (error) {
            print('ChatController: Error en stream de mensajes: $error');
            state = state.copyWith(
              currentChatMessages: AsyncValue.error(error, StackTrace.current),
            );
          },
          onDone: () {
            print('ChatController: Stream de mensajes cerrado.');
            _messageSubscription = null;
          },
          cancelOnError: true,
        );
  }

  Future<void> sendMessage(String chatId, String content) async {
    if (_currentUserId == null) {
      state = state.copyWith(errorMessage: 'User not logged in');
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _chatRepository.sendMessage(chatId, _currentUserId, content);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> unsubscribeFromMessages() async {
    if (_messageSubscription != null) {
      await _messageSubscription?.cancel();
      _messageSubscription = null;
      print(
        'ChatController: Suscripción de mensajes cancelada explícitamente.',
      );
      state = state.copyWith(currentChatMessages: const AsyncValue.data([]));
    }
  }
}
