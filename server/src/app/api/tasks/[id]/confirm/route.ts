import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

// PATCH /api/tasks/:id/confirm — 家长确认任务完成
export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const { id: taskId } = await params;

  const taskLog = await prisma.taskLog.findUnique({ where: { id: taskId } });
  if (!taskLog) return fail("任务记录不存在", 404);
  if (taskLog.userId !== userId) return fail("无权操作此任务", 403);
  if (taskLog.confirmed) return fail("任务已确认");

  const updated = await prisma.taskLog.update({
    where: { id: taskId },
    data: { confirmed: true },
  });

  return ok(updated);
}
