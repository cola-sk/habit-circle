import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

const RIPE_THRESHOLD = 3000; // 成熟期最低周期积分

// POST /api/pets/harvest — 孩子发起兑换，重置当前周期积分，记录收成
export async function POST(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const pet = await prisma.pet.findUnique({ where: { ownerId: userId } });
  if (!pet) return fail("宠物不存在", 404);

  if ((pet.currentCyclePoints ?? 0) < RIPE_THRESHOLD) {
    return fail("西瓜还没成熟，继续加油！");
  }

  const newHarvestCount = (pet.harvestCount ?? 0) + 1;

  const [updatedPet, harvestRecord] = await prisma.$transaction([
    // 重置当前周期，保留历史 totalPoints 和 level
    prisma.pet.update({
      where: { ownerId: userId },
      data: {
        currentCyclePoints: 0,
        harvestCount: newHarvestCount,
        hungerStatus: "normal",
      },
    }),
    // 写入收成记录（shippedAt 由工作人员后续填写）
    prisma.harvestRecord.create({
      data: {
        petId: pet.id,
        cycleNumber: newHarvestCount,
        pointsAtHarvest: pet.currentCyclePoints ?? 0,
        redeemedAt: new Date(),
      },
    }),
  ]);

  return ok({ pet: updatedPet, harvest: harvestRecord });
}

// GET /api/pets/harvest — 获取当前用户的所有收成记录
export async function GET(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const pet = await prisma.pet.findUnique({ where: { ownerId: userId } });
  if (!pet) return ok([]);

  const records = await prisma.harvestRecord.findMany({
    where: { petId: pet.id },
    orderBy: { cycleNumber: "asc" },
  });

  return ok(records);
}
