import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

const cheerSchema = z.object({
  toUserId: z.string().min(1),
});

// POST /api/cheers — 给某人加油（每人每天对同一目标最多一次）
export async function POST(req: NextRequest) {
  const fromUserId = await getAuthUser(req);
  if (!fromUserId) return unauthorized();

  const body = await req.json().catch(() => null);
  const parsed = cheerSchema.safeParse(body);
  if (!parsed.success) return fail(parsed.error.errors[0].message);

  const { toUserId } = parsed.data;

  if (fromUserId === toUserId) return fail("不能给自己加油哦");

  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

  try {
    await prisma.cheer.create({
      data: { fromUserId, toUserId, date: today },
    });
  } catch {
    // unique constraint：今天已经给他加过油了
    return fail("今天已经给他加过油啦");
  }

  return ok({ success: true });
}

// GET /api/cheers?date=YYYY-MM-DD — 查询我今天收到的【未读】加油，返回送加油人的昵称列表
export async function GET(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const { searchParams } = new URL(req.url);
  const date = searchParams.get("date") ?? new Date().toISOString().slice(0, 10);

  const cheers = await prisma.cheer.findMany({
    where: { toUserId: userId, date, readAt: null },
    include: {
      fromUser: {
        select: { childName: true },
      },
    },
    orderBy: { createdAt: "asc" },
  });

  const names = cheers.map((c) => c.fromUser.childName || "小朋友");
  return ok({ date, count: cheers.length, cheerers: names });
}

// PATCH /api/cheers — 将我今天所有未读加油标记为已读
export async function PATCH(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const today = new Date().toISOString().slice(0, 10);

  await prisma.cheer.updateMany({
    where: { toUserId: userId, date: today, readAt: null },
    data: { readAt: new Date() },
  });

  return ok({ success: true });
}
