import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const TASK_TEMPLATES = [
  {
    key: "reading",
    name: "自主阅读",
    emoji: "📚",
    colorHex: "#4FC3F7",
    pointsPer15Min: 10,
    isTimeBased: true,
    evidenceTypes: ["audio", "image", "video"],
    sortOrder: 1,
    isDefault: false,
  },
  {
    key: "piano",
    name: "练琴",
    emoji: "🎹",
    colorHex: "#CE93D8",
    pointsPer15Min: 15,
    isTimeBased: true,
    evidenceTypes: ["audio", "image", "video"],
    sortOrder: 2,
    isDefault: true,
  },
  {
    key: "english",
    name: "英语绘本",
    emoji: "🌍",
    colorHex: "#80CBC4",
    pointsPer15Min: 12,
    isTimeBased: true,
    evidenceTypes: ["audio", "image", "video"],
    sortOrder: 3,
    isDefault: true,
  },
  {
    key: "preview",
    name: "课程预习",
    emoji: "📖",
    colorHex: "#A5D6A7",
    pointsPer15Min: 10,
    isTimeBased: true,
    evidenceTypes: ["image", "video"],
    sortOrder: 4,
    isDefault: true,
  },
  {
    key: "homework",
    name: "完成作业",
    emoji: "✏️",
    colorHex: "#FFCC80",
    pointsPer15Min: 20,
    isTimeBased: false,
    evidenceTypes: ["image", "video"],
    sortOrder: 5,
    isDefault: true,
  },
  {
    key: "jump_rope",
    name: "跳绳",
    emoji: "🪢",
    colorHex: "#FFD54F",
    pointsPer15Min: 10,
    isTimeBased: true,
    evidenceTypes: ["video"],
    sortOrder: 6,
    isDefault: true,
  },
  {
    key: "tidy_toys",
    name: "整理玩具",
    emoji: "🧸",
    colorHex: "#A5D6A7",
    pointsPer15Min: 8,
    isTimeBased: false,
    evidenceTypes: ["image", "video"],
    sortOrder: 7,
    isDefault: false,
  },
  {
    key: "dress_self",
    name: "独立穿衣",
    emoji: "👕",
    colorHex: "#80CBC4",
    pointsPer15Min: 8,
    isTimeBased: false,
    evidenceTypes: ["image", "video"],
    sortOrder: 8,
    isDefault: false,
  },
  {
    key: "chores",
    name: "小家务",
    emoji: "🧹",
    colorHex: "#FFCC80",
    pointsPer15Min: 8,
    isTimeBased: false,
    evidenceTypes: ["image", "video"],
    sortOrder: 9,
    isDefault: false,
  },
];

async function main() {
  console.log("🌱 开始写入全局任务模板...");
  for (const tpl of TASK_TEMPLATES) {
    await prisma.taskTemplate.upsert({
      where: { key: tpl.key },
      update: {
        name: tpl.name,
        emoji: tpl.emoji,
        colorHex: tpl.colorHex,
        pointsPer15Min: tpl.pointsPer15Min,
        isTimeBased: tpl.isTimeBased,
        evidenceTypes: tpl.evidenceTypes,
        sortOrder: tpl.sortOrder,
        isDefault: tpl.isDefault,
      },
      create: tpl,
    });
    console.log(`  ✅ ${tpl.emoji} ${tpl.name}`);
  }
  console.log("🎉 完成！");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
