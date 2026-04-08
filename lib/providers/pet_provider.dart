import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pet_model.dart';
import '../repositories/pet_repository.dart';
import '../providers/circle_provider.dart';
import '../providers/auth_provider.dart';

/// 当前用户的宠物（AsyncNotifierProvider 以便任务完成后直接更新状态）
final myPetProvider =
    AsyncNotifierProvider<MyPetNotifier, PetModel?>(MyPetNotifier.new);

class MyPetNotifier extends AsyncNotifier<PetModel?> {
  @override
  Future<PetModel?> build() {
    final isLoggedIn = ref.watch(authStateNotifierProvider).isLoggedIn;
    if (!isLoggedIn) return Future.value(null);
    return ref.watch(petRepositoryProvider).fetchMyPet();
  }

  /// 任务完成后，直接用服务端返回的最新 pet 覆盖本地缓存，无需重新 fetch
  void updateFromServer(PetModel pet) {
    state = AsyncData(pet);
  }

  /// 兑换西瓜：调用 API 后积分重置，本地状态直接更新
  Future<void> harvestPet() async {
    final updated = await ref.read(petRepositoryProvider).harvestPet();
    state = AsyncData(updated);
  }
}

/// 圈子内所有宠物
final circlePetsProvider = FutureProvider<List<PetModel>>((ref) {
  final circle = ref.watch(myCircleProvider).valueOrNull;
  if (circle == null) return Future.value([]);
  return ref.watch(petRepositoryProvider).fetchCirclePets(circle.id);
});
