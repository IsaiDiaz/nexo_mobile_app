// lib/data/chat_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/data/auth_repository.dart'; // Necesitamos acceder a PocketBase
import 'package:nexo/model/chat.dart';
import 'package:nexo/model/message.dart';
import 'dart:async'; // Necesario para StreamController

class ChatRepository {
  final pb.PocketBase _pocketBase;

  ChatRepository(this._pocketBase);

  pb.PocketBase get pocketBaseInstance => _pocketBase;

  /// Obtiene todos los chats en los que participa el usuario actual.
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      final records = await _pocketBase
          .collection('chat')
          .getFullList(
            filter: 'first_user = "${userId}" || second_user = "${userId}"',
            expand:
                'first_user,second_user', // Para obtener detalles de los usuarios en el chat
            sort: '-updated', // Ordenar por el mensaje más reciente o actividad
          );
      return records.map((record) => Chat.fromRecord(record)).toList();
    } catch (e) {
      print('Error getting user chats: $e');
      throw Exception('Failed to load user chats');
    }
  }

  /// Busca un chat existente entre dos usuarios o lo crea si no existe.
  Future<Chat> findOrCreateChat(String userId1, String userId2) async {
    try {
      var records = await _pocketBase
          .collection('chat')
          .getFullList(
            filter:
                '(first_user = "${userId1}" && second_user = "${userId2}") || (first_user = "${userId2}" && second_user = "${userId1}")',
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

  /// Obtiene los mensajes históricos de un chat.
  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final records = await _pocketBase
          .collection('messages')
          .getFullList(
            filter: 'chat = "${chatId}"',
            expand: 'user', // Para obtener detalles del remitente
            sort: 'created', // Ordenar por fecha de creación (ascendente)
          );
      return records.map((record) => Message.fromRecord(record)).toList();
    } catch (e) {
      print('Error getting chat messages: $e');
      throw Exception('Failed to load chat messages');
    }
  }

  /// Envía un nuevo mensaje a un chat.
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
            // Opcional: si quieres que el 'user' se expanda inmediatamente al crear.
            // query: {'expand': 'user'}, // No afecta a las suscripciones
          );
      return Message.fromRecord(record);
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  /// Suscribe a los cambios en los mensajes de un chat específico.
  /// Retorna un `Stream` de `Message`.
  Stream<Message> subscribeToChatMessages(String chatId) {
    final StreamController<Message> controller = StreamController<Message>();

    // ====================================================================
    // === Corrección para el error: AWAIT el resultado de subscribe  ===
    // ====================================================================
    late pb.UnsubscribeFunc unsubscribeFunc; // Declarar aquí

    // Usamos .then() para asignar el UnsubscribeFunc una vez que el Future se complete
    _pocketBase
        .collection('messages')
        .subscribe(
          '*', // Suscribirse a todos los eventos de la colección messages
          (e) async {
            // <-- El callback es async para poder hacer getOne
            // Solo procesamos el evento si el mensaje pertenece al chat que nos interesa
            if (e.record != null && e.record!.data['chat'] == chatId) {
              try {
                // CLAVE: Obtener el Record completo con 'user' expandido
                final fullRecord = await _pocketBase
                    .collection('messages')
                    .getOne(
                      e.record!.id,
                      query: {'expand': 'user'}, // <-- ¡Expandir 'user' aquí!
                    );
                final message = Message.fromRecord(fullRecord);
                controller.add(message);
              } catch (fetchError) {
                print(
                  'Error fetching expanded message record for realtime: $fetchError',
                );
                // Si falla la obtención expandida, puedes optar por añadir el mensaje sin expandir
                // o simplemente omitirlo. Por ahora, lo omitimos para evitar errores de UI.
                // controller.add(Message.fromRecord(e.record!));
              }
            }
          },
          filter:
              'chat = "$chatId"', // Esto es bueno y funciona para filtrar eventos
        )
        .then((func) {
          // <-- Asignar el resultado del Future aquí
          unsubscribeFunc = func;
        })
        .catchError((error) {
          // Manejar errores si la suscripción inicial falla
          print('Error subscribing to chat messages: $error');
          controller.addError(error); // Pasa el error al Stream
          controller.close(); // Cierra el stream si la suscripción falla
        });

    // Cuando el stream deja de ser escuchado, desuscribimos
    controller.onCancel = () {
      if (unsubscribeFunc != null) {
        // Asegurarse de que ya se asignó
        unsubscribeFunc(); // Llamar a la función de desuscripción
      }
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
