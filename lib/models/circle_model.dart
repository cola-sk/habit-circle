class CircleModel {
  final String id;
  final String name;
  final String inviteCode;
  final String creatorId;
  final List<String> memberUids;
  final DateTime createdAt;

  const CircleModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.creatorId,
    required this.memberUids,
    required this.createdAt,
  });

  factory CircleModel.fromJson(Map<String, dynamic> data) => CircleModel(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        inviteCode: data['inviteCode'] as String? ?? '',
        creatorId: data['creatorId'] as String? ?? '',
        memberUids: (data['members'] as List<dynamic>? ?? [])
            .map((m) => m['userId'] as String)
            .toList(),
        createdAt:
            DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  int get memberCount => memberUids.length;
  bool isMember(String uid) => memberUids.contains(uid);
}
