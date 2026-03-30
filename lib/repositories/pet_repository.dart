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

  Future<List<PetModel>> fetchCirclePets(String circleId) =>
      _fetchCirclePets(circleId);

  Future<List<PetModel>> _fetchCirclePets(String circleId) async {
    try {
      final data = await _client.get(ApiEndpoints.circleById(circleId));
      final members = data['members'] as List<dynamic>;
      return members
          .map((m) => m['pet'])
          .whereType<Map<String, dynamic>>()
          .map(PetModel.fromJson)
          .toList();
    } on ApiException {
      return [];
    }
  }
}
