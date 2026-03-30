import { PrismaClient } from "@prisma/client";

// Vercel Postgres: DATABASE_URL 使用连接池地址（pgBouncer）
// DIRECT_URL 使用直连地址（用于 prisma migrate）
// 两个变量由 Vercel 控制台 Storage → Connect to Project 自动注入
const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
