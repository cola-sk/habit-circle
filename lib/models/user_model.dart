class UserModel {
  final String uid;
  final String phone;
  final String childName;
  final String? circleId;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.phone,
    required this.childName,
    this.circleId,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> data) => UserModel(
        uid: data['id'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        childName: data['childName'] as String? ?? '',
        circleId: data['circleId'] as String?,
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  UserModel copyWith({
    String? childName,
    String? circleId,
  }) =>
      UserModel(
        uid: uid,
        phone: phone,
        childName: childName ?? this.childName,
        circleId: circleId ?? this.circleId,
        createdAt: createdAt,
      );
}
