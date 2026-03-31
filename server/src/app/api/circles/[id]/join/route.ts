import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

// POST /api/circles/[id]/join  — 直接按圈子 ID 加入（无需邀请码）
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const { id } = await params;

  const circle = await prisma.circle.findUnique({
    where: { id },
    include: { members: { select: { id: true } } },
  });

  if (!circle) return fail("圈子不存在", 404);
  if (circle.members.length >= 20) return fail("圈子人数已满（最多 20 人）");
  if (circle.members.some((m) => m.id === userId)) {
    return fail("您已经在这个圈子里了");
  }

  // 如果已在其他圈子，先退出
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { circleId: true },
  });
  if (user?.circleId && user.circleId !== id) {
    await prisma.circle.update({
      where: { id: user.circleId },
      data: { members: { disconnect: { id: userId } } },
    });
  }

  await prisma.circle.update({
    where: { id },
    data: { members: { connect: { id: userId } } },
  });

  return ok({
    id: circle.id,
    name: circle.name,
    memberCount: circle.members.length + 1,
  });
}
