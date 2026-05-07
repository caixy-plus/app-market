class AppConfig {
  // 对接统一 backend 服务 (本地 K8s 域名)
  static const String baseUrl = 'https://api.local.caixy.xin';
  static const int connectTimeoutSeconds = 10;
  static const int receiveTimeoutSeconds = 30;
  static const int defaultPageSize = 20;
}
