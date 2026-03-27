# 技术架构设计

## 技术选型

### 为什么选 Flutter + Firebase

| 维度 | 选择 | 理由 |
|------|------|------|
| **客户端** | Flutter 3 | 一套代码同时覆盖 iOS / Android；Dart 语言学习曲线平缓；动画能力强（适合宠物交互）；社区成熟 |
| **后端** | Firebase | 无服务器，MVP 阶段免费额度充足；Firestore 实时数据库完美支持圈子广场；Auth 开箱即用；Push 通知免费 |
| **状态管理** | Riverpod 2 | Flutter 最主流的响应式状态管理，适合中小项目 |
| **本地存储** | Hive | 纯 Dart，支持离线任务记录 |
| **动画** | Rive | 矢量宠物动画（呼吸、开心、饥饿状态切换） |

---

## 系统架构图

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │   UI     │  │  State   │  │   Local Storage  │  │
│  │ (Widgets)│  │(Riverpod)│  │     (Hive)       │  │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘  │
│       └─────────────┴─────────────────┘             │
│                      │                              │
│              Repository Layer                        │
│         (抽象数据访问，支持离线/在线)                │
└──────────────────────┬──────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
  Firebase Auth  Firestore DB   FCM Push
  (手机号登录)  (实时数据)    (每日提醒)
```

---

## Firebase 数据结构

### Firestore Collections

```
/users/{uid}
  - uid: string
  - phone: string
  - childName: string          # 孩子昵称
  - circleId: string | null    # 所属圈子 ID
  - createdAt: timestamp

/pets/{uid}
  - ownerId: string            # 对应 users/{uid}
  - name: string               # 宠物名字
  - species: string            # cat | dog | rabbit | dragon
  - level: number              # 1-10
  - totalPoints: number        # 历史累计总积分
  - lastFedAt: timestamp       # 最后喂食时间
  - hungerStatus: string       # happy | normal | hungry | starving | critical
  - createdAt: timestamp

/circles/{circleId}
  - name: string               # 圈子名称
  - inviteCode: string         # 6位邀请码
  - creatorUid: string
  - memberUids: string[]       # 成员 uid 列表
  - createdAt: timestamp

/taskLogs/{logId}
  - uid: string                # 完成者
  - taskType: string           # reading | piano | english | preview | homework | exercise | custom
  - taskName: string           # 任务名称（自定义任务时使用）
  - durationMinutes: number    # 完成时长（分钟）
  - points: number             # 获得积分
  - completed: boolean
  - date: string               # YYYY-MM-DD，方便按天查询
  - createdAt: timestamp

/dailyFeeds/{uid_date}          # 文档 ID = "{uid}_{YYYY-MM-DD}"
  - uid: string
  - date: string               # YYYY-MM-DD
  - pointsEarned: number       # 当天任务积分
  - pointsFed: number          # 当天喂食积分
  - fedAt: timestamp | null
```

### Firestore Security Rules 要点

```javascript
// 用户只能读写自己的数据
// 圈子成员可以读取同圈所有宠物信息（公开展示）
// 圈子信息任何登录用户可通过 inviteCode 查询
```

---

## 项目目录结构

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + Router 配置
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── task_types.dart           # 任务类型定义
│   │   └── pet_species.dart          # 宠物种类定义
│   ├── theme/
│   │   └── app_theme.dart
│   ├── router/
│   │   └── app_router.dart           # GoRouter 路由配置
│   └── utils/
│       ├── date_utils.dart
│       └── points_calculator.dart    # 积分计算逻辑
│
├── models/
│   ├── user_model.dart
│   ├── pet_model.dart
│   ├── task_log_model.dart
│   ├── circle_model.dart
│   └── daily_feed_model.dart
│
├── repositories/
│   ├── auth_repository.dart
│   ├── pet_repository.dart
│   ├── task_repository.dart
│   ├── circle_repository.dart
│   └── feed_repository.dart
│
├── providers/                        # Riverpod providers
│   ├── auth_provider.dart
│   ├── pet_provider.dart
│   ├── task_provider.dart
│   ├── circle_provider.dart
│   └── timer_provider.dart
│
└── features/
    ├── onboarding/                   # 新用户引导
    │   ├── screens/
    │   │   ├── welcome_screen.dart
    │   │   ├── phone_auth_screen.dart
    │   │   ├── create_profile_screen.dart  # 填孩子名字
    │   │   ├── choose_pet_screen.dart
    │   │   └── circle_setup_screen.dart    # 创建/加入圈子
    │   └── widgets/
    │
    ├── home/                         # 首页（我的宠物）
    │   ├── screens/
    │   │   └── home_screen.dart
    │   └── widgets/
    │       ├── pet_display_widget.dart     # 宠物动画展示
    │       ├── hunger_bar_widget.dart      # 饥饿值/成长值条
    │       ├── feed_button_widget.dart     # 喂食按钮
    │       └── today_summary_widget.dart  # 今日积分摘要
    │
    ├── tasks/                        # 任务页
    │   ├── screens/
    │   │   └── tasks_screen.dart
    │   └── widgets/
    │       ├── task_card_widget.dart
    │       └── task_timer_widget.dart      # 计时器弹窗
    │
    ├── circle/                       # 圈子广场
    │   ├── screens/
    │   │   └── circle_screen.dart
    │   └── widgets/
    │       ├── pet_card_widget.dart        # 圈子内宠物卡片
    │       └── leaderboard_widget.dart    # 今日积分榜
    │
    └── profile/                      # 我的页面
        ├── screens/
        │   └── profile_screen.dart
        └── widgets/
            └── invite_code_widget.dart    # 邀请码/二维码分享
```

---

## 关键技术决策

### 1. 宠物动画方案
- 使用 **Rive** 制作矢量宠物动画（状态机：idle/happy/hungry/eating）
- 每种宠物 3 个成长阶段 × 4 个动画状态 = 12 个动画片段
- 文件大小约 200-500KB/宠物，可接受

### 2. 饥饿值计算（本地 + 云端双向）
```dart
// 每天凌晨 00:00 Server-side Cloud Function 重置饥饿检查
// 客户端实时展示：根据 lastFedAt 和当前时间计算饥饿状态
HungerStatus calculateHunger(DateTime lastFedAt, double todayPoints) {
  final hoursSinceFed = DateTime.now().difference(lastFedAt).inHours;
  if (hoursSinceFed < 24 && todayPoints >= 80) return HungerStatus.happy;
  // ...
}
```

### 3. 离线支持
- 任务计时完全本地（Hive）
- 积分记录本地缓存，联网后同步 Firestore
- 宠物状态读取优先本地缓存，后台刷新

### 4. 推送通知
- Firebase Cloud Functions 定时任务（每天 20:00）
- 检查当天未喂食的用户，发送 FCM 通知

---

## 开发环境要求

- Flutter 3.19+
- Dart 3.3+
- Xcode 15+ (iOS 构建)
- Firebase CLI
- FlutterFire CLI
