/**
 * 短信验证码发送
 *
 * 开发模式（未配置 ALIYUN_ACCESS_KEY_ID）：
 *   直接在终端打印验证码，方便本地调试
 *
 * 生产模式：
 *   对接阿里云短信服务，也可替换为腾讯云短信 SDK
 */

export async function sendSms(phone: string, code: string): Promise<void> {
  const isDev =
    !process.env.ALIYUN_ACCESS_KEY_ID ||
    process.env.NODE_ENV === "development";

  if (isDev) {
    // 开发模式：打印到终端，不实际发送
    console.log(`\n📱 [DEV SMS] 手机号: ${phone}  验证码: ${code}\n`);
    return;
  }

  // ── 生产模式：阿里云短信 ──────────────────────────────────────
  // 安装 SDK: npm install @alicloud/dysmsapi20170525 @alicloud/openapi-client
  //
  // import Dysmsapi from '@alicloud/dysmsapi20170525';
  // import OpenApi from '@alicloud/openapi-client';
  //
  // const config = new OpenApi.Config({
  //   accessKeyId: process.env.ALIYUN_ACCESS_KEY_ID,
  //   accessKeySecret: process.env.ALIYUN_ACCESS_KEY_SECRET,
  //   endpoint: 'dysmsapi.aliyuncs.com',
  // });
  // const client = new Dysmsapi(config);
  // await client.sendSms({
  //   phoneNumbers: phone,
  //   signName: process.env.ALIYUN_SMS_SIGN_NAME,
  //   templateCode: process.env.ALIYUN_SMS_TEMPLATE_CODE,
  //   templateParam: JSON.stringify({ code }),
  // });

  throw new Error("生产环境请配置阿里云短信 SDK");
}
