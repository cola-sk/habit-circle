import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

// DELETE /api/user-tasks/:id — 删除用户任务
export async function DELETE(
  req: NextRequest,
  context: RouteContext<"/api/user-tasks/[id]">
) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const { id } = await context.params;

  const userTask = await prisma.userTask.findUnique({ where: { id } });
  if (!userTask) return fail("任务不存在", 404);
  if (userTask.userId !== userId) return fail("无权操作此任务", 403);

  await prisma.userTask.delete({ where: { id } });

  return ok({ id });
}
