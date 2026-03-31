import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

const createSchema = z.object({
  name: z.string().min(1).max(8),
  species: z.enum(["watermelon", "cat", "dog", "rabbit", "dragon", "hamster"]),
});

// POST /api/pets  — 创建宠物
export async function POST(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const body = await req.json().catch(() => null);
  const parsed = createSchema.safeParse(body);
  if (!parsed.success) return fail(parsed.error.errors[0].message);

  const existing = await prisma.pet.findUnique({ where: { ownerId: userId } });
  if (existing) return fail("已经有宠物了");

  // 汇总创建前已完成的任务积分，避免宠物初始 totalPoints 为 0
  const agg = await prisma.taskLog.aggregate({
    where: { userId },
    _sum: { points: true },
  });
  const totalPoints = agg._sum.points ?? 0;

  const LEVEL_THRESHOLDS = [0, 200, 500, 1000, 1800, 3000, 4500, 6500, 9000, 12000];
  let level = 1;
  for (let i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
    if (totalPoints >= LEVEL_THRESHOLDS[i]) { level = i + 1; break; }
  }

  const pet = await prisma.pet.create({
    data: {
      ownerId: userId,
      name: parsed.data.name,
      species: parsed.data.species,
      totalPoints,
      level,
    },
  });

  return ok(pet, 201);
}

// GET /api/pets  — 获取当前用户的宠物
export async function GET(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const pet = await prisma.pet.findUnique({ where: { ownerId: userId } });
  // 还没有西瓜是正常状态，返回 null 而非报错
  return ok(pet ?? null);
}
