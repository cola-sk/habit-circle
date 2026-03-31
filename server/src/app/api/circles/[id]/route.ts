import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail } from "@/lib/response";

// GET /api/circles/[id]  — 公开获取圈子信息（含成员宠物），无需登录
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;

  // 当前用户（可能为空/未登录）
  const userId = await getAuthUser(req).catch(() => null);

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

  const isMember = userId
    ? circle.members.some((m) => m.id === userId)
    : false;

  return ok({
    id: circle.id,
    name: circle.name,
    inviteCode: isMember ? circle.inviteCode : null,
    memberCount: circle.members.length,
    isMember,
    members: circle.members.map((m) => ({
      userId: m.id,
      childName: m.childName,
      pet: m.pet,
    })),
  });
}
