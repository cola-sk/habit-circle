import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

function generateInviteCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  return Array.from({ length: 6 }, () =>
    chars[Math.floor(Math.random() * chars.length)]
  ).join("");
}

// GET /api/circles  — 公开获取所有圈子列表（无需登录）
export async function GET() {
  const circles = await prisma.circle.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      members: {
        select: {
          id: true,
          childName: true,
          pet: { select: { name: true, level: true, totalPoints: true, species: true } },
        },
      },
    },
  });

  return ok({
    circles: circles.map((c) => ({
      id: c.id,
      name: c.name,
      memberCount: c.members.length,
      members: c.members.map((m) => ({
        userId: m.id,
        childName: m.childName,
        pet: m.pet,
      })),
      createdAt: c.createdAt,
    })),
  });
}


const createSchema = z.object({
  name: z.string().min(1).max(15),
});

export async function POST(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const body = await req.json().catch(() => null);
  const parsed = createSchema.safeParse(body);
  if (!parsed.success) return fail(parsed.error.errors[0].message);

  // 已经在圈子里了
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (user?.circleId) return fail("您已经在圈子里了，请先退出");

  // 生成唯一邀请码（避免碰撞）
  let inviteCode = generateInviteCode();
  let attempts = 0;
  while (await prisma.circle.findUnique({ where: { inviteCode } })) {
    inviteCode = generateInviteCode();
    if (++attempts > 10) return fail("服务繁忙，请重试", 500);
  }

  const circle = await prisma.circle.create({
    data: {
      name: parsed.data.name,
      inviteCode,
      creatorId: userId,
      members: { connect: { id: userId } },
    },
  });

  return ok({
    id: circle.id,
    name: circle.name,
    inviteCode: circle.inviteCode,
    memberCount: 1,
  }, 201);
}
