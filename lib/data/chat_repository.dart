import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/auth_repository.dart';
import 'package:nexo/model/chat.dart';
import 'package:nexo/model/message.dart';
import 'dart:async';

class ChatRepository {
  final pb.PocketBase _pocketBase;

  ChatRepository(this._pocketBase);

  pb.PocketBase get pocketBaseInstance => _pocketBase;

  Future<List<Chat>> getUserChats(String userId) async {
    try {
      final records = await _pocketBase
          .collection('chat')
          .getFullList(
            filter: 'first_user = "$userId" || second_user = "$userId"',
            expand: 'first_user,second_user',
            sort: '-updated',
          );
      return records.map((record) => Chat.fromRecord(record)).toList();
    } catch (e) {
      print('Error getting user chats: $e');
      throw Exception('Failed to load user chats');
    }
  }

  Future<Chat> findOrCreateChat(String userId1, String userId2) async {
    try {
      var records = await _pocketBase
          .collection('chat')
          .getFullList(
            filter:
                '(first_user = "$userId1" && second_user = "$userId2") || (first_user = "$userId2" && second_user = "$userId1")',
            expand: 'first_user,second_user',
          );

      if (records.isNotEmpty) {
        return Chat.fromRecord(records.first);
      } else {
        final newChatRecord = await _pocketBase
            .collection('chat')
            .create(body: {'first_user': userId1, 'second_user': userId2});
        return Chat.fromRecord(newChatRecord);
      }
    } catch (e) {
      print('Error finding or creating chat: $e');
      throw Exception('Failed to find or create chat');
    }
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final records = await _pocketBase
          .collection('messages')
          .getFullList(
            filter: 'chat = "$chatId"',
            expand: 'user',
            sort: 'created',
          );
      return records.map((record) => Message.fromRecord(record)).toList();
    } catch (e) {
      print('Error getting chat messages: $e');
      throw Exception('Failed to load chat messages');
    }
  }

  Future<Message> sendMessage(
    String chatId,
    String senderId,
    String content,
  ) async {
    try {
      final record = await _pocketBase
          .collection('messages')
          .create(
            body: {
              'chat': chatId,
              'user': senderId,
              'message_content': content,
            },
          );
      return Message.fromRecord(record);
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  Stream<Message> subscribeToChatMessages(String chatId) {
    final StreamController<Message> controller = StreamController<Message>();

    late pb.UnsubscribeFunc unsubscribeFunc;

    _pocketBase
        .collection('messages')
        .subscribe('*', (e) async {
          if (e.record != null && e.record!.data['chat'] == chatId) {
            try {
              final fullRecord = await _pocketBase
                  .collection('messages')
                  .getOne(e.record!.id, query: {'expand': 'user'});
              final message = Message.fromRecord(fullRecord);
              controller.add(message);
            } catch (fetchError) {
              print(
                'Error fetching expanded message record for realtime: $fetchError',
              );
            }
          }
        }, filter: 'chat = "$chatId"')
        .then((func) {
          unsubscribeFunc = func;
        })
        .catchError((error) {
          print('Error subscribing to chat messages: $error');
          controller.addError(error);
          controller.close();
        });

    controller.onCancel = () {
      unsubscribeFunc();
      controller.close();
      print('Suscripción a chat $chatId cancelada y StreamController cerrado.');
    };

    return controller.stream;
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final pocketBase = ref.read(authRepositoryProvider).pocketBase;
  return ChatRepository(pocketBase);
});
