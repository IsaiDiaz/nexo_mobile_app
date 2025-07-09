import 'package:pocketbase/pocketbase.dart';

class Chat {
  final String id;
  final String firstUserId;
  final String secondUserId;
  final DateTime createdAt;

  final RecordModel? firstUserRecord;
  final RecordModel? secondUserRecord;

  Chat({
    required this.id,
    required this.firstUserId,
    required this.secondUserId,
    required this.createdAt,
    this.firstUserRecord,
    this.secondUserRecord,
  });

  factory Chat.fromRecord(RecordModel record) {
    print('DEBUG Chat.fromRecord - record.data: ${record.data}');

    final firstUserId = record.data['first_user'] as String;
    final secondUserId = record.data['second_user'] as String;
    final createdAtString = record.data['created'] as String;
    final parsedCreatedAt = DateTime.parse(createdAtString);

    final RecordModel? expandedFirstUserRecord = record.get<RecordModel?>(
      "expand.first_user",
    );
    final RecordModel? expandedSecondUserRecord = record.get<RecordModel?>(
      "expand.second_user",
    );

    return Chat(
      id: record.id,
      firstUserId: firstUserId,
      secondUserId: secondUserId,
      createdAt: parsedCreatedAt,
      firstUserRecord: expandedFirstUserRecord,
      secondUserRecord: expandedSecondUserRecord,
    );
  }

  String getOtherParticipantId(String currentUserId) {
    if (firstUserId == currentUserId) {
      return secondUserId;
    } else if (secondUserId == currentUserId) {
      return firstUserId;
    }
    throw Exception("Current user is not a participant in this chat.");
  }
}
