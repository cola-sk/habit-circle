import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

// GET /api/circles/[id]  — 获取圈子信息（含成员宠物）
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const { id } = await params;

  const circle = await prisma.circle.findUnique({
    where: { id },
    include: {
      members: {
        select: {
          id: true,
          childName: true,
          pet: true,
        },
      },
    },
  });

  if (!circle) return fail("圈子不存在", 404);

  // 验证当前用户是圈子成员
  const isMember = circle.members.some((m) => m.id === userId);
  if (!isMember) return fail("您不在这个圈子里", 403);

  return ok({
    id: circle.id,
    name: circle.name,
    inviteCode: circle.inviteCode,
    memberCount: circle.members.length,
    members: circle.members.map((m) => ({
      userId: m.id,
      childName: m.childName,
      pet: m.pet,
    })),
  });
}
