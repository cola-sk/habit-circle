import 'pet_model.dart';

class CircleMember {
  final String userId;
  final String childName;
  final PetModel? pet;

  const CircleMember({
    required this.userId,
    required this.childName,
    this.pet,
  });

  factory CircleMember.fromJson(Map<String, dynamic> data) => CircleMember(
        userId: data['userId'] as String? ?? '',
        childName: data['childName'] as String? ?? '',
        pet: data['pet'] != null
            ? PetModel.fromJson(data['pet'] as Map<String, dynamic>)
            : null,
      );
}

class CircleModel {
  final String id;
  final String name;
  final String inviteCode;
  final String creatorId;
  final List<String> memberUids;
  final List<CircleMember> members;
  final bool isMember;
  final DateTime createdAt;

  const CircleModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.creatorId,
    required this.memberUids,
    this.members = const [],
    this.isMember = false,
    required this.createdAt,
  });

  factory CircleModel.fromJson(Map<String, dynamic> data) {
    final memberList = (data['members'] as List<dynamic>? ?? [])
        .map((m) => CircleMember.fromJson(m as Map<String, dynamic>))
        .toList();
    return CircleModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      memberUids: memberList.map((m) => m.userId).toList(),
      members: memberList,
      isMember: data['isMember'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  int get memberCount => memberUids.length;
  bool isMemberOf(String uid) => memberUids.contains(uid);
}
