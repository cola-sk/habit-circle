import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { sendSms } from "@/lib/sms";
import { ok, fail } from "@/lib/response";

const schema = z.object({
  phone: z.string().regex(/^1[3-9]\d{9}$/, "手机号格式不正确"),
});

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return fail(parsed.error.errors[0].message);

  const { phone } = parsed.data;

  // 60 秒内不重复发送
  const recent = await prisma.smsCode.findFirst({
    where: {
      phone,
      used: false,
      createdAt: { gte: new Date(Date.now() - 60_000) },
    },
  });
  if (recent) return fail("发送太频繁，请 60 秒后重试", 429);

  // 生成 6 位数字验证码
  const code = String(Math.floor(100000 + Math.random() * 900000));
  const expiresAt = new Date(Date.now() + 10 * 60_000); // 10 分钟有效

  await prisma.smsCode.create({ data: { phone, code, expiresAt } });
  await sendSms(phone, code);

  // 未配置短信服务时，把验证码明文返回，方便开发调试
  const isSmsMocked = !process.env.ALIYUN_ACCESS_KEY_ID;
  return ok({
    message: "验证码已发送",
    ...(isSmsMocked && { code }),
  });
}
