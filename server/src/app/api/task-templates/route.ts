import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, unauthorized } from "@/lib/response";

// GET /api/task-templates — 返回所有激活的全局任务模板
export async function GET(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const templates = await prisma.taskTemplate.findMany({
    where: { isActive: true },
    orderBy: { sortOrder: "asc" },
  });

  return ok(templates);
}
