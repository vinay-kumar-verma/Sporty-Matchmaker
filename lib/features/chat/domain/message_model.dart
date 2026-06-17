class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? '',
        text: map['text'] ?? '',
        createdAt: DateTime.parse(map['createdAt']),
      );
}