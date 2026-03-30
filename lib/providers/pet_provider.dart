import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pet_model.dart';
import '../repositories/pet_repository.dart';
import '../providers/circle_provider.dart';
import '../providers/auth_provider.dart';

/// 当前用户的宠物
final myPetProvider = FutureProvider<PetModel?>((ref) {
  final isLoggedIn = ref.watch(authStateNotifierProvider).isLoggedIn;
  if (!isLoggedIn) return Future.value(null);
  return ref.watch(petRepositoryProvider).fetchMyPet();
});

/// 圈子内所有宠物
final circlePetsProvider = FutureProvider<List<PetModel>>((ref) {
  final circle = ref.watch(myCircleProvider).valueOrNull;
  if (circle == null) return Future.value([]);
  return ref.watch(petRepositoryProvider).fetchCirclePets(circle.id);
});

/// 喂食操作
final feedPetProvider =
    StateNotifierProvider<FeedPetNotifier, AsyncValue<void>>(
  (ref) => FeedPetNotifier(ref),
);

class FeedPetNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FeedPetNotifier(this._ref) : super(const AsyncData(null));

  Future<void> feed(int points) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _ref.read(petRepositoryProvider).feedPet(points),
    );
  }
}
