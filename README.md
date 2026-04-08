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
- **Next.js + Prisma**（`server/` 目录，服务端 API，PostgreSQL/Neon）

---

## 新环境搭建指南

### 前置依赖

| 工具 | 推荐版本 | 安装参考 |
|------|---------|---------|
| Flutter | 3.x | https://docs.flutter.dev/get-started/install |
| Dart | 3.x（Flutter 自带） | — |
| Node.js | 20+ | https://nodejs.org |
| pnpm | 9+ | `npm i -g pnpm` |
| Android Studio / Xcode | 最新稳定版 | Flutter 官方文档 |

验证环境：

```bash
flutter doctor
```

---

### 1. 克隆并安装依赖

```bash
git clone <repo-url>
cd habit-circle

# Flutter 依赖
flutter pub get

# 服务端依赖
cd server && pnpm install
```

---

### 2. 配置服务端环境变量

**推荐：直接从 Vercel 拉取（有项目权限时）**

```bash
cd server
pnpm i -g vercel   # 若未安装 vercel CLI
vercel link        # 关联到 Vercel 项目（首次需要登录并选择项目）
vercel env pull .env.local
```

拉取后 `.env.local` 会自动包含 `DATABASE_URL`、`BLOB_READ_WRITE_TOKEN` 等所有生产/预览环境变量，无需手动填写。

---

**手动配置（无 Vercel 权限时）**

```bash
cd server
cp .env.example .env.local
```

编辑 `.env.local`，填入以下关键字段：

```env
# PostgreSQL 连接（推荐 Neon 免费套餐）
DATABASE_URL="postgresql://user:password@host/db?sslmode=require&pgbouncer=true"
DIRECT_URL="postgresql://user:password@host/db?sslmode=require"

# Vercel Blob（用于存储任务证据文件）
BLOB_READ_WRITE_TOKEN="vercel_blob_rw_xxxx"

# JWT 密钥（开发可用默认值，生产必须替换）
JWT_SECRET="your-super-secret-key"
JWT_EXPIRES_IN="30d"

# 阿里云短信（开发时留空，验证码会打印到终端）
ALIYUN_ACCESS_KEY_ID=""
ALIYUN_ACCESS_KEY_SECRET=""
```

初始化数据库并写入默认任务模板：

```bash
cd server
pnpm prisma db push          # 同步 schema 到数据库
pnpm prisma db seed          # 写入任务模板数据
```

---

### 3. 启动本地服务端

```bash
cd server
pnpm dev
# 默认监听 http://localhost:3000
```

---

### 4. 运行 Flutter

**Android 真机/模拟器：**

```bash
flutter run
# API 默认指向线上 https://hc-server.tz0618.uk
# 若要连本地服务端：
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # Android 模拟器
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000 # 真机（填本机局域网 IP）
```

**Chrome 调试：**

```bash
flutter run -d chrome --web-port 8081 \
  --dart-define=API_BASE_URL=http://localhost:3000
```

**iOS 模拟器：**

```bash
flutter run -d simulator \
  --dart-define=API_BASE_URL=http://localhost:3000
```

---

### 5. Mock 模式（无需服务端）

`lib/main.dart` 中将 `useMock` 改为 `true`，即可使用本地假数据运行，无需连接任何服务：

```dart
const bool useMock = true;
```

---

## 构建

### Android APK

```bash
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
flutter build ios --release
# 需要 Xcode + Apple Developer 账号
```

---

## 文档

- [产品需求文档 (PRD)](docs/PRD.md)
- [技术架构设计](docs/ARCHITECTURE.md)
- [AI Agent 项目说明](AGENTS.md)
