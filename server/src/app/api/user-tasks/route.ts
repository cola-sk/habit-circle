import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

const addSchema = z.object({
  templateId: z.string().min(1),
});

// GET /api/user-tasks — 查询当前用户已启用任务（含模板详情）；首次访问自动写入默认任务
export async function GET(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const existing = await prisma.userTask.findMany({
    where: { userId },
    include: { template: true },
    orderBy: { template: { sortOrder: "asc" } },
  });

  // 首次使用：自动写入 isDefault=true 的模板
  if (existing.length === 0) {
    const defaults = await prisma.taskTemplate.findMany({
      where: { isDefault: true, isActive: true },
    });
    if (defaults.length > 0) {
      await prisma.userTask.createMany({
        data: defaults.map((t) => ({ userId, templateId: t.id })),
        skipDuplicates: true,
      });
      const seeded = await prisma.userTask.findMany({
        where: { userId },
        include: { template: true },
        orderBy: { template: { sortOrder: "asc" } },
      });
      return ok(seeded);
    }
  }

  return ok(existing);
}

// POST /api/user-tasks — 新增用户任务（从全局模板选择）
export async function POST(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const body = await req.json().catch(() => null);
  const parsed = addSchema.safeParse(body);
  if (!parsed.success) return fail(parsed.error.errors[0].message);

  const { templateId } = parsed.data;

  // 确认模板存在且激活
  const template = await prisma.taskTemplate.findUnique({
    where: { id: templateId, isActive: true },
  });
  if (!template) return fail("任务模板不存在", 404);

  // 已添加则直接返回已有记录（幂等）
  const existing = await prisma.userTask.findUnique({
    where: { userId_templateId: { userId, templateId } },
    include: { template: true },
  });
  if (existing) return ok(existing);

  const userTask = await prisma.userTask.create({
    data: { userId, templateId },
    include: { template: true },
  });

  return ok(userTask, 201);
}
