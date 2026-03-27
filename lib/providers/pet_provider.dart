import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pet_model.dart';
import '../repositories/pet_repository.dart';
import '../providers/circle_provider.dart';

/// 当前用户的宠物（轮询流）
final myPetProvider = StreamProvider<PetModel?>(
  (ref) => ref.watch(petRepositoryProvider).watchPet(),
);

/// 圈子内所有宠物（通过圈子 ID 轮询）
final circlePetsProvider = StreamProvider<List<PetModel>>((ref) {
  final circle = ref.watch(myCircleProvider).valueOrNull;
  if (circle == null) return Stream.value([]);
  return ref.watch(petRepositoryProvider).watchCirclePets(circle.id);
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
