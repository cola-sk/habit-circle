/// 根据环境切换 API 地址
class ApiEndpoints {
  ApiEndpoints._();

  /// 开发时：Next.js 本地服务
  /// 发布时：换成你的服务器域名
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Auth
  static const sendCode   = '/api/auth/send-code';
  static const verifyCode = '/api/auth/verify-code';

  // Users
  static const me = '/api/users/me';

  // Pets
  static const pets     = '/api/pets';
  static const feedPet  = '/api/pets/feed';

  // Tasks
  static const tasks = '/api/tasks';
  static String taskEvidence(String taskId) => '/api/tasks/$taskId/evidence';
  static String taskConfirm(String taskId)  => '/api/tasks/$taskId/confirm';

  // Circles
  static const circles     = '/api/circles';
  static const joinCircle  = '/api/circles/join';
  static String circleById(String id) => '/api/circles/$id';
}
