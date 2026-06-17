class GameModel {
  final String id;
  final String hostId;
  final String hostName;
  final String sport;
  final String venue;
  final DateTime dateTime;
  final int totalPlayersNeeded;
  final List<String> joinedPlayerIds;
  final String skillLevel;
  final String? notes;
  final DateTime createdAt;

  const GameModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.sport,
    required this.venue,
    required this.dateTime,
    required this.totalPlayersNeeded,
    required this.joinedPlayerIds,
    required this.skillLevel,
    this.notes,
    required this.createdAt,
  });

  int get playersJoined => joinedPlayerIds.length;
  int get spotsLeft => totalPlayersNeeded - playersJoined;
  bool get isFull => spotsLeft <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'sport': sport,
      'venue': venue,
      'dateTime': dateTime.toIso8601String(),
      'totalPlayersNeeded': totalPlayersNeeded,
      'joinedPlayerIds': joinedPlayerIds,
      'skillLevel': skillLevel,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GameModel.fromMap(Map<String, dynamic> map) {
    return GameModel(
      id: map['id'] ?? '',
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      sport: map['sport'] ?? '',
      venue: map['venue'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      totalPlayersNeeded: map['totalPlayersNeeded'] ?? 2,
      joinedPlayerIds: List<String>.from(map['joinedPlayerIds'] ?? []),
      skillLevel: map['skillLevel'] ?? 'Beginner',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}