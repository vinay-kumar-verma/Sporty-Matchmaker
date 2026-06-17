import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../domain/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<MessageModel>> getMessages(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data()))
            .toList());
  }

  Future<String?> getHostId(String gameId) async {
    final doc = await _firestore
        .collection('games')
        .doc(gameId)
        .get();
    return doc.data()?['hostId'] as String?;
  }

  Future<void> sendMessage({
    required String gameId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final id = _uuid.v4();
    final message = MessageModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      text: text,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('messages')
        .doc(id)
        .set(message.toMap());
  }
}