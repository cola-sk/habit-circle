import { NextRequest } from "next/server";
import { put } from "@vercel/blob";
import { prisma } from "@/lib/prisma";
import { getAuthUser } from "@/lib/auth";
import { ok, fail, unauthorized } from "@/lib/response";

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB
const ALLOWED_TYPES: Record<string, string> = {
  "image/jpeg": "image",
  "image/png": "image",
  "image/webp": "image",
  "audio/mpeg": "audio",
  "audio/mp4": "audio",
  "audio/wav": "audio",
  "audio/webm": "audio",
};

// POST /api/tasks/:id/evidence — 上传任务证明（图片或音频）
export async function POST(
  req: NextRequest,
  context: RouteContext<"/api/tasks/[id]/evidence">
) {
  const userId = await getAuthUser(req);
  if (!userId) return unauthorized();

  const { id: taskId } = await context.params;

  // 确认该任务属于当前用户
  const taskLog = await prisma.taskLog.findUnique({ where: { id: taskId } });
  if (!taskLog) return fail("任务记录不存在", 404);
  if (taskLog.userId !== userId) return fail("无权操作此任务", 403);
  if (taskLog.evidenceUrl) return fail("证明已上传，不可重复提交", 409);

  const formData = await req.formData().catch(() => null);
  if (!formData) return fail("请求格式错误，需要 multipart/form-data");

  const file = formData.get("file");
  if (!(file instanceof File)) return fail("缺少 file 字段");

  const evidenceType = ALLOWED_TYPES[file.type];
  if (!evidenceType) return fail("不支持的文件类型，仅支持图片（jpg/png/webp）和音频（mp3/wav/webm）");
  if (file.size > MAX_FILE_SIZE) return fail("文件大小不能超过 10MB");

  const ext = file.name.split(".").pop() ?? "bin";
  const blobPath = `evidence/${userId}/${taskId}.${ext}`;

  const blob = await put(blobPath, file, {
    access: "public",
    contentType: file.type,
  });

  const updated = await prisma.taskLog.update({
    where: { id: taskId },
    data: {
      evidenceUrl: blob.url,
      evidenceType,
    },
  });

  return ok({ evidenceUrl: updated.evidenceUrl, evidenceType: updated.evidenceType }, 201);
}
