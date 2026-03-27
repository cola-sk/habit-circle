import { NextRequest } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

// GET /api/users/me
export async function GET(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return fail("用户不存在", 404);

  return ok({
    id: user.id,
    phone: user.phone,
    childName: user.childName,
    circleId: user.circleId,
    createdAt: user.createdAt,
  });
}

// PATCH /api/users/me
const patchSchema = z.object({
  childName: z.string().min(1).max(10).optional(),
});

export async function PATCH(req: NextRequest) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const body = await req.json().catch(() => null);
  const parsed = patchSchema.safeParse(body);
  if (!parsed.success) return fail(parsed.error.errors[0].message);

  const user = await prisma.user.update({
    where: { id: userId },
    data: parsed.data,
  });

  return ok({
    id: user.id,
    childName: user.childName,
    circleId: user.circleId,
  });
}
