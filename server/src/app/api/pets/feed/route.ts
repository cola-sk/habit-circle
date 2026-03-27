import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

const LEVEL_THRESHOLDS = [0, 200, 500, 1000, 1800, 3000, 4500, 6500, 9000, 12000];

function levelFromPoints(total: number): number {
  for (let i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
    if (total >= LEVEL_THRESHOLDS[i]) return i + 1;
  }
  return 1;
}

function hungerStatusFromPoints(points: number): string {
  if (points >= 80) return "happy";
  if (points >= 60) return "normal";
  if (points >= 30) return "hungry";
  if (points >= 1)  return "starving";
  return "critical";
}

const feedSchema = z.object({
  points: z.number().int().positive(),
});

// POST /api/pets/feed
export async function POST(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const body = await req.json().catch(() => null);
  const parsed = feedSchema.safeParse(body);
  if (!parsed.success) return fail("积分参数不合法");

  const { points } = parsed.data;

  const pet = await prisma.pet.findUnique({ where: { ownerId: userId } });
  if (!pet) return fail("宠物不存在", 404);

  // 判断今天是否已喂食
  const now = new Date();
  if (pet.lastFedAt) {
    const last = pet.lastFedAt;
    const sameDay =
      last.getFullYear() === now.getFullYear() &&
      last.getMonth() === now.getMonth() &&
      last.getDate() === now.getDate();
    if (sameDay) return fail("今天已经喂过了");
  }

  const newTotal = pet.totalPoints + points;
  const newLevel = levelFromPoints(newTotal);
  const newStatus = hungerStatusFromPoints(points);

  const updated = await prisma.pet.update({
    where: { ownerId: userId },
    data: {
      totalPoints: newTotal,
      level: newLevel,
      lastFedAt: now,
      hungerStatus: newStatus,
    },
  });

  const leveledUp = newLevel > pet.level;
  return ok({ pet: updated, leveledUp });
}
