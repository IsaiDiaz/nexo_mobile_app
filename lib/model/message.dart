import 'package:pocketbase/pocketbase.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  final RecordModel? senderRecord;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderRecord,
  });

  factory Message.fromRecord(RecordModel record) {
    final chatId = record.data['chat'] as String;
    final senderId = record.data['user'] as String;
    final content = record.data['message_content'] as String;

    final createdAtString = record.data['created'] as String;
    final parsedCreatedAt = DateTime.parse(createdAtString);

    final RecordModel? expandedSenderRecord = record.get<RecordModel?>(
      "expand.user",
    );

    return Message(
      id: record.id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      createdAt: parsedCreatedAt,
      senderRecord: expandedSenderRecord,
    );
  }

  Map<String, dynamic> toJson() {
    return {'chat': chatId, 'user': senderId, 'message_content': content};
  }
}
