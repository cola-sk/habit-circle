# HabitCircle · 养西瓜 🍉

> **养西瓜 = 养习惯**  
> 专为小圈子小学生设计的习惯养成 App：完成学习任务 → 积分浇水 → 西瓜从种子长成大西瓜

## 项目简介

HabitCircle 是一款 Flutter 应用，帮助一个小圈子里的小学生（如兴趣班、学而思班级）坚持完成学习任务，通过养一个虚拟西瓜来可视化习惯养成的过程。

孩子每天完成练琴、英语绘本、自主阅读、课程预习等任务，按时长获得积分，积分用来给自己的西瓜"浇水"——西瓜从种子慢慢长大，坚持越久，西瓜越大，习惯越牢固。

圈子内所有小朋友的西瓜会展示在"圈子广场"，形成正向的同伴激励。

## 技术栈

- **Flutter 3** + **Dart 3**（iOS & Android）
- **Riverpod 2** 状态管理
- **Firebase**（Firestore + Auth + FCM）
- **Hive** 本地离线存储
- **Rive** 西瓜/宠物动画
- **Next.js**（server/ 目录，服务端补充 API）

## 快速开始

```bash
flutter pub get
flutter run
```

## 文档

- [产品需求文档 (PRD)](docs/PRD.md)
- [技术架构设计](docs/ARCHITECTURE.md)
- [AI Agent 项目说明](AGENTS.md)
