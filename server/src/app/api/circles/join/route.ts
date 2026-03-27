import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

const joinSchema = z.object({
  inviteCode: z.string().length(6),
});

// POST /api/circles/join
export async function POST(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const body = await req.json().catch(() => null);
  const parsed = joinSchema.safeParse(body);
  if (!parsed.success) return fail("邀请码格式不正确");

  const { inviteCode } = parsed.data;

  const circle = await prisma.circle.findUnique({
    where: { inviteCode: inviteCode.toUpperCase() },
    include: { members: { select: { id: true } } },
  });

  if (!circle) return fail("邀请码无效");
  if (circle.members.length >= 20) return fail("圈子人数已满（最多 20 人）");
  if (circle.members.some((m) => m.id === userId)) {
    return fail("您已经在这个圈子里了");
  }

  // 加入圈子
  await prisma.circle.update({
    where: { id: circle.id },
    data: { members: { connect: { id: userId } } },
  });

  return ok({
    id: circle.id,
    name: circle.name,
    inviteCode: circle.inviteCode,
    memberCount: circle.members.length + 1,
  });
}
