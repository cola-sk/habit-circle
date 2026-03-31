import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const LEVEL_THRESHOLDS = [0, 200, 500, 1000, 1800, 3000, 4500, 6500, 9000, 12000];

function levelFromPoints(total: number): number {
  for (let i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
    if (total >= LEVEL_THRESHOLDS[i]) return i + 1;
  }
  return 1;
}

async function main() {
  const pets = await prisma.pet.findMany({ select: { ownerId: true, totalPoints: true } });
  let fixed = 0;
  for (const pet of pets) {
    const agg = await prisma.taskLog.aggregate({
      where: { userId: pet.ownerId },
      _sum: { points: true },
    });
    const correct = agg._sum.points ?? 0;
    console.log(`  ownerId=${pet.ownerId}  db.totalPoints=${pet.totalPoints}  taskLogSum=${correct}`);
    if (correct !== pet.totalPoints) {
      const level = levelFromPoints(correct);
      await prisma.pet.update({
        where: { ownerId: pet.ownerId },
        data: { totalPoints: correct, level },
      });
      console.log(`fixed ownerId=${pet.ownerId}  totalPoints: ${pet.totalPoints} -> ${correct}  level -> ${level}`);
      fixed++;
    }
  }
  console.log(`\ndone. fixed ${fixed} / ${pets.length} pets.`);
}

main().finally(() => prisma.$disconnect());
