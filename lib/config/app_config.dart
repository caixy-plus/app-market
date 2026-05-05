class AppConfig {
  // 对接统一 backend 服务
  static const String baseUrl = 'http://192.168.124.22:8080';
  static const int connectTimeoutSeconds = 10;
  static const int receiveTimeoutSeconds = 30;
  static const int defaultPageSize = 20;
}
