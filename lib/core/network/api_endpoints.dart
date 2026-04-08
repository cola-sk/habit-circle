/// 根据环境切换 API 地址
class ApiEndpoints {
  ApiEndpoints._();

  /// 开发时：Next.js 本地服务
  /// 发布时：https://hc-server.tz0618.uk
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hc-server.tz0618.uk',
  );

  // Auth
  static const sendCode   = '/api/auth/send-code';
  static const verifyCode = '/api/auth/verify-code';

  // Users
  static const me = '/api/users/me';

  // Pets
  static const pets       = '/api/pets';
  static const feedPet    = '/api/pets/feed';
  static const harvestPet = '/api/pets/harvest';

  // Tasks
  static const tasks = '/api/tasks';
  static String taskEvidence(String taskId) => '/api/tasks/$taskId/evidence';
  static String taskConfirm(String taskId)  => '/api/tasks/$taskId/confirm';

  // Task templates & user tasks
  static const taskTemplates = '/api/task-templates';
  static const userTasks = '/api/user-tasks';
  static String userTaskById(String id) => '/api/user-tasks/$id';

  // Cheers
  static const cheers = '/api/cheers';
  static const circles     = '/api/circles';
  static const joinCircle  = '/api/circles/join';
  static String circleById(String id) => '/api/circles/$id';
  static String circleJoinById(String id) => '/api/circles/$id/join';
}
