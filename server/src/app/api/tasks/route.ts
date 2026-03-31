import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

const POINTS_PER_15_MIN: Record<string, number> = {
  reading: 10,
  piano: 15,
  english: 12,
  preview: 10,
  homework: 20,
  exercise: 8,
  custom: 10,
};

const TIME_BASED = new Set(["reading", "piano", "english", "preview", "exercise", "custom"]);

function calcPoints(taskType: string, durationMinutes: number): number {
  const base = POINTS_PER_15_MIN[taskType] ?? 10;
  if (!TIME_BASED.has(taskType)) return base; // 固定积分
  const units = Math.floor(durationMinutes / 15);
  return units * base;
}

function todayDate(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

const LEVEL_THRESHOLDS = [0, 200, 500, 1000, 1800, 3000, 4500, 6500, 9000, 12000];

function levelFromPoints(total: number): number {
  for (let i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
    if (total >= LEVEL_THRESHOLDS[i]) return i + 1;
  }
  return 1;
}

function hungerStatusFromPoints(todayPoints: number): string {
  if (todayPoints >= 80) return "happy";
  if (todayPoints >= 60) return "normal";
  if (todayPoints >= 30) return "hungry";
  if (todayPoints >= 1)  return "starving";
  return "critical";
}

const createSchema = z.object({
  taskType: z.enum(["reading", "piano", "english", "preview", "homework", "exercise", "custom"]),
  taskName: z.string().min(1).max(20).optional(),
  durationMinutes: z.number().int().min(0),
});

// POST /api/tasks  — 提交完成任务
export async function POST(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const body = await req.json().catch(() => null);
  const parsed = createSchema.safeParse(body);
  if (!parsed.success) return fail(parsed.error.errors[0].message);

  const { taskType, taskName, durationMinutes } = parsed.data;
  const points = calcPoints(taskType, durationMinutes);

  if (points === 0 && TIME_BASED.has(taskType)) {
    return fail("至少需要 15 分钟才能获得积分");
  }

  const log = await prisma.taskLog.create({
    data: {
      userId,
      taskType,
      taskName: taskName ?? taskType,
      durationMinutes,
      points,
      date: todayDate(),
    },
  });

  // 完成任务后立即累加西瓜积分，无需单独"喂食"操作
  let updatedPet = null;
  if (points > 0) {
    const pet = await prisma.pet.findUnique({ where: { ownerId: userId } });
    if (pet) {
      const newTotal = pet.totalPoints + points;
      const newLevel = levelFromPoints(newTotal);
      // 当天所有已存在任务积分 + 本次积分 = 今日总积分（决定西瓜状态）
      const todayLogs = await prisma.taskLog.findMany({
        where: { userId, date: todayDate(), id: { not: log.id } },
        select: { points: true },
      });
      const todayTotal = todayLogs.reduce((s, l) => s + l.points, 0) + points;
      const newStatus = hungerStatusFromPoints(todayTotal);
      updatedPet = await prisma.pet.update({
        where: { ownerId: userId },
        data: { totalPoints: newTotal, level: newLevel, hungerStatus: newStatus },
      });
    }
  }

  return ok({ log, pet: updatedPet }, 201);
}

// GET /api/tasks?date=YYYY-MM-DD  — 查询某天任务记录（默认今天）
export async function GET(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const { searchParams } = new URL(req.url);
  const date = searchParams.get("date") ?? todayDate();

  const logs = await prisma.taskLog.findMany({
    where: { userId, date },
    orderBy: { createdAt: "desc" },
  });

  const totalPoints = logs.reduce((sum, l) => sum + l.points, 0);

  return ok({ logs, totalPoints, date });
}
