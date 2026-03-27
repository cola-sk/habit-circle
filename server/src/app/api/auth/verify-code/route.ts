import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { signToken } from "@/lib/auth";
import { ok, fail } from "@/lib/response";

const schema = z.object({
  phone: z.string().regex(/^1[3-9]\d{9}$/),
  code: z.string().length(6),
});

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return fail("参数错误");

  const { phone, code } = parsed.data;

  // 查找未使用且未过期的验证码
  const smsCode = await prisma.smsCode.findFirst({
    where: {
      phone,
      code,
      used: false,
      expiresAt: { gte: new Date() },
    },
    orderBy: { createdAt: "desc" },
  });

  if (!smsCode) return fail("验证码无效或已过期");

  // 标记为已使用
  await prisma.smsCode.update({
    where: { id: smsCode.id },
    data: { used: true },
  });

  // 查找或创建用户
  const user = await prisma.user.upsert({
    where: { phone },
    update: {},
    create: { phone },
  });

  const token = await signToken({ userId: user.id });

  return ok({
    token,
    user: {
      id: user.id,
      phone: user.phone,
      childName: user.childName,
      circleId: user.circleId,
    },
    isNewUser: !user.childName,
  });
}
