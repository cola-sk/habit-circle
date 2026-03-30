import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const phone = process.argv[2] || '13800000000';

async function clean() {
  const user = await prisma.user.findFirst({ where: { phone } });
  if (!user) {
    console.log(`用户 ${phone} 不存在，无需清除`);
    return;
  }
  await prisma.pet.deleteMany({ where: { ownerId: user.id } });
  await prisma.taskLog.deleteMany({ where: { userId: user.id } });
  await prisma.smsCode.deleteMany({ where: { phone } });
  await prisma.user.delete({ where: { id: user.id } });
  console.log(`✅ 清除完成：${phone}，可以重新走注册流程`);
}

clean().finally(() => prisma.$disconnect());
