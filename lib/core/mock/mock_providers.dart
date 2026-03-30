import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/circle_model.dart';
import '../../models/pet_model.dart';
import '../../models/task_log_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/circle_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/task_provider.dart';
import '../constants/pet_species.dart';
import '../constants/task_types.dart';

// ── Mock 数据 ─────────────────────────────────────────────────────────────────

int _levelFor(int totalPoints) =>
    PetLevelThresholds.levelFromPoints(totalPoints);

final _mockUser = UserModel(
  uid: 'mock-uid-001',
  phone: '138****8888',
  childName: '小明',
  circleId: 'mock-circle-001',
  createdAt: DateTime(2026, 1, 1),
);

final _mockPet = PetModel(
  ownerId: 'mock-uid-001',
  name: '大西瓜',
  species: PetSpecies.cat,
  totalPoints: 2580,
  level: _levelFor(2580),
  hungerStatus: HungerStatus.happy,
  lastFedAt: DateTime.now(),
  createdAt: DateTime(2026, 1, 1),
);

final _mockCircle = CircleModel(
  id: 'mock-circle-001',
  name: '开心秘密花园',
  inviteCode: 'XG2026',
  creatorId: 'mock-uid-001',
  memberUids: [
    'mock-uid-001',
    'mock-uid-002',
    'mock-uid-003',
    'mock-uid-004',
  ],
  createdAt: DateTime(2026, 1, 1),
);

final _mockCirclePets = [
  _mockPet,
  PetModel(
    ownerId: 'mock-uid-002',
    name: 'Oliver',
    species: PetSpecies.rabbit,
    totalPoints: 1200,
    level: _levelFor(1200),
    hungerStatus: HungerStatus.normal,
    lastFedAt: DateTime.now().subtract(const Duration(hours: 5)),
    createdAt: DateTime(2026, 1, 10),
  ),
  PetModel(
    ownerId: 'mock-uid-003',
    name: 'Sophia',
    species: PetSpecies.hamster,
    totalPoints: 380,
    level: _levelFor(380),
    hungerStatus: HungerStatus.hungry,
    lastFedAt: DateTime.now().subtract(const Duration(hours: 10)),
    createdAt: DateTime(2026, 2, 1),
  ),
  PetModel(
    ownerId: 'mock-uid-004',
    name: 'Leo',
    species: PetSpecies.dog,
    totalPoints: 820,
    level: _levelFor(820),
    hungerStatus: HungerStatus.normal,
    lastFedAt: DateTime.now().subtract(const Duration(hours: 2)),
    createdAt: DateTime(2026, 1, 20),
  ),
];

final _mockTaskLogs = [
  TaskLogModel(
    id: 't1',
    uid: 'mock-uid-001',
    taskType: TaskType.reading,
    taskName: '自主阅读',
    durationMinutes: 30,
    points: 30,
    completed: true,
    date: DateTime.now().toIso8601String().substring(0, 10),
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  TaskLogModel(
    id: 't2',
    uid: 'mock-uid-001',
    taskType: TaskType.piano,
    taskName: '练琴',
    durationMinutes: 20,
    points: 20,
    completed: true,
    date: DateTime.now().toIso8601String().substring(0, 10),
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  TaskLogModel(
    id: 't3',
    uid: 'mock-uid-001',
    taskType: TaskType.homework,
    taskName: '完成作业',
    durationMinutes: 45,
    points: 45,
    completed: false,
    date: DateTime.now().toIso8601String().substring(0, 10),
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
];

// ── Provider Overrides ────────────────────────────────────────────────────────

/// 在 ProviderScope 中使用此列表替换真实 providers
final mockOverrides = <Override>[
  // 当前用户
  currentUserProvider.overrideWith(
    (ref) => Stream.value(_mockUser),
  ),

  // 我的宠物
  myPetProvider.overrideWith(
    (ref) => Stream.value(_mockPet),
  ),

  // 我的圈子
  myCircleProvider.overrideWith(
    (ref) => Stream.value(_mockCircle),
  ),

  // 圈子内所有宠物
  circlePetsProvider.overrideWith(
    (ref) => Stream.value(_mockCirclePets),
  ),

  // 今日任务记录
  todayTaskLogsProvider.overrideWith(
    (ref) => Stream.value(_mockTaskLogs),
  ),
];
