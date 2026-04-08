import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/cheer_repository.dart';

/// 今日收到的加油人昵称列表
final todayCheersProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(cheerRepositoryProvider).fetchTodayCheers();
});
