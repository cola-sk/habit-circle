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

  const pet = await prisma.pet.create({
    data: {
      ownerId: userId,
      name: parsed.data.name,
      species: parsed.data.species,
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
