import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/pet_model.dart';
import '../core/constants/pet_species.dart';

final petRepositoryProvider = Provider<PetRepository>(
  (ref) => PetRepository(ref.watch(apiClientProvider)),
);

class PetRepository {
  final ApiClient _client;
  PetRepository(this._client);

  Future<PetModel?> fetchMyPet() => _fetchMyPet();

  Future<PetModel?> _fetchMyPet() async {
    try {
      final data = await _client.getNullable(ApiEndpoints.pets);
      if (data == null) return null;
      return PetModel.fromJson(data);
    } on ApiException {
      return null;
    }
  }

  Future<void> createPet({
    required String name,
    required PetSpecies species,
  }) async {
    await _client.post(ApiEndpoints.pets, body: {
      'name': name,
      'species': species.name,
    });
  }

  Future<void> feedPet(int points) async {
    await _client.post(ApiEndpoints.feedPet, body: {'points': points});
  }

  /// 兑换西瓜：重置周期积分，返回更新后的 pet
  Future<PetModel> harvestPet() async {
    final data = await _client.post(ApiEndpoints.harvestPet, body: {});
    return PetModel.fromJson(data['pet'] as Map<String, dynamic>);
  }

  Future<List<PetModel>> fetchCirclePets(String circleId) =>
      _fetchCirclePets(circleId);

  Future<List<PetModel>> _fetchCirclePets(String circleId) async {
    try {
      final data = await _client.get(ApiEndpoints.circleById(circleId));
      final members = data['members'] as List<dynamic>;
      return members
          .whereType<Map<String, dynamic>>()
          .where((m) => m['pet'] != null)
          .map((m) {
            final petJson = Map<String, dynamic>.from(
                m['pet'] as Map<String, dynamic>);
            petJson['ownerName'] = m['childName'] as String? ?? '';
            return PetModel.fromJson(petJson);
          })
          .toList();
    } on ApiException {
      return [];
    }
  }
}
