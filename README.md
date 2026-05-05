# 应用商城 - 移动端 (App Market Mobile)

应用商城跨平台移动端客户端，基于 Flutter 构建，支持 Android、iOS、macOS、Windows、Linux 和 Web。

## 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| 框架 | Flutter | 3.19+ |
| 语言 | Dart | 3.0+ |
| 状态管理 | Provider | ^6.1.1 |
| 网络请求 | Dio | ^5.4.0 |
| 本地存储 | SharedPreferences | ^2.2.2 |
| 图片加载 | CachedNetworkImage | ^3.3.1 |

## 功能特性

- 应用浏览与搜索：按分类浏览、关键词搜索、排序筛选
- 应用详情：查看应用信息、评分、版本历史
- 安装管理：一键安装/卸载应用
- 用户系统：登录注册、个人中心
- 评分评论：对已安装应用进行评分和评论
- 脑池 AI 对话：接入平台统一大模型 API
- 自动 Token 续期：支持 Refresh Token 机制，401 时自动刷新

## 项目结构

```
lib/
├── api/              # API 客户端与数据模型
│   ├── api_client.dart    # Dio 封装 + 自动 Token 刷新
│   └── mock_data.dart     # 开发期 Mock 数据
├── config/           # 应用配置
├── models/           # 数据模型
├── providers/        # 状态管理 (Provider)
├── screens/          # 页面
│   ├── home_screen.dart
│   ├── app_list_screen.dart
│   ├── app_detail_screen.dart
│   ├── login_screen.dart
│   ├── profile_screen.dart
│   └── ...
test/                 # 单元测试
integration_test/     # 集成测试
```

## 开发环境

### 前置要求

- Flutter SDK ^3.10.1
- Android Studio / Xcode (根据目标平台)
- 运行中的后端服务 (本地 :8080)

### 启动步骤

```bash
# 安装依赖
flutter pub get

# 运行开发版本（自动选择可用设备）
flutter run

# 或指定平台
flutter run -d macos
flutter run -d android
flutter run -d ios
```

### 构建发布包

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release
```

## 配置说明

API 基础地址根据平台自动适配：
- Android: `http://192.168.124.22:8080`
- iOS/macOS/Windows: `http://localhost:8080`

修改 `lib/config/app_config.dart` 可自定义。

## 测试

```bash
# 单元测试
flutter test

# 集成测试
flutter test integration_test/app_test.dart
```
