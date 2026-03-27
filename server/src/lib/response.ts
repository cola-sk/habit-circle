import { NextResponse } from "next/server";

export const ok = (data: unknown, status = 200) =>
  NextResponse.json({ success: true, data }, { status });

export const fail = (message: string, status = 400) =>
  NextResponse.json({ success: false, message }, { status });

export const unauthorized = () => fail("未登录或 token 已过期", 401);
