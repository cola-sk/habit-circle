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

  return ok(log, 201);
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
