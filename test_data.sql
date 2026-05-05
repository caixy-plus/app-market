-- ============================================================
-- Flutter 应用商城测试数据插入脚本
-- 只插入 app_store_apps 表，不改服务端代码
-- ============================================================

-- 清理旧数据（如果存在）
TRUNCATE TABLE app_store_apps RESTART IDENTITY CASCADE;

-- 插入测试应用数据
INSERT INTO app_store_apps (id, slug, name, short_desc, full_desc, category, tags, icon_url, pricing_type, price_cents, version, manifest_url, install_count, rating_avg, rating_count, status, published_at, created_at, updated_at) VALUES
(1, 'vscode', 'VS Code', '轻量级但强大的源代码编辑器', 'Visual Studio Code 是一款运行于 macOS、Windows 和 Linux 之上的，针对于编写现代 Web 和云应用的跨平台源代码编辑器。', '开发工具', '["editor", "ide", "microsoft"]', 'https://code.visualstudio.com/assets/images/code-stable.png', 'free', 0, '1.85.0', 'https://code.visualstudio.com/download', 12580, 4.8, 3420, 'PUBLISHED', NOW() - INTERVAL '120 days', NOW() - INTERVAL '120 days', NOW()),
(2, 'flutter', 'Flutter SDK', 'Google 开源的 UI 工具包', 'Flutter 是 Google 的开源框架，用于从单一代码库构建适用于移动、Web 和桌面的原生编译应用程序。', '开发工具', '["framework", "google", "dart"]', 'https://storage.googleapis.com/cms-storage-bucket/6a07d8a62f4308d2b854.svg', 'free', 0, '3.19.0', 'https://docs.flutter.dev/get-started/install', 8900, 4.7, 2100, 'PUBLISHED', NOW() - INTERVAL '110 days', NOW() - INTERVAL '110 days', NOW()),
(3, 'notion', 'Notion', '集笔记、任务、数据库于一体的工作空间', 'Notion 是一款集笔记、知识库、任务管理和项目管理于一体的协作工具，支持多端同步。', '生产力', '["notes", "productivity", "collaboration"]', 'https://www.notion.so/images/logo-ios.png', 'freemium', 0, '3.0.0', 'https://www.notion.so/desktop', 15600, 4.6, 5600, 'PUBLISHED', NOW() - INTERVAL '100 days', NOW() - INTERVAL '100 days', NOW()),
(4, 'obsidian', 'Obsidian', '强大的知识库工具', 'Obsidian 是一款基于本地 Markdown 文件的笔记和知识管理工具，支持双向链接和丰富的插件生态。', '生产力', '["notes", "markdown", "knowledge"]', 'https://obsidian.md/favicon.ico', 'free', 0, '1.5.0', 'https://obsidian.md/download', 7200, 4.9, 1800, 'PUBLISHED', NOW() - INTERVAL '90 days', NOW() - INTERVAL '90 days', NOW()),
(5, 'docker-desktop', 'Docker Desktop', '容器化应用开发平台', 'Docker Desktop 是 Docker 的官方桌面应用程序，使开发者能够轻松构建、共享和运行容器化应用程序。', '开发工具', '["container", "devops", "virtualization"]', 'https://www.docker.com/wp-content/uploads/2023/04/docker-logo-blue.svg', 'free', 0, '4.27.0', 'https://www.docker.com/products/docker-desktop', 9800, 4.5, 2400, 'PUBLISHED', NOW() - INTERVAL '80 days', NOW() - INTERVAL '80 days', NOW()),
(6, 'figma', 'Figma', '协作式界面设计工具', 'Figma 是一款基于浏览器的协作界面设计工具，支持实时协作、原型设计和设计系统管理。', '设计', '["design", "ui", "collaboration"]', 'https://cdn.sanity.io/images/59924g8x/production/5ee13cbc2a2576f4a313b9a5dbf4aeca9c5ec52d-128x128.png', 'freemium', 0, '116.0', 'https://www.figma.com/downloads', 11200, 4.7, 3100, 'PUBLISHED', NOW() - INTERVAL '70 days', NOW() - INTERVAL '70 days', NOW()),
(7, 'postman', 'Postman', 'API 开发与测试平台', 'Postman 是一个 API 平台，用于构建和使用 API，简化了 API 生命周期的每个步骤并简化了协作。', '开发工具', '["api", "testing", "development"]', 'https://www.postman.com/favicon.ico', 'free', 0, '10.22.0', 'https://www.postman.com/downloads', 8500, 4.4, 1900, 'PUBLISHED', NOW() - INTERVAL '60 days', NOW() - INTERVAL '60 days', NOW()),
(8, 'termius', 'Termius', '跨平台 SSH 客户端', 'Termius 是一款现代化的 SSH 客户端，支持跨平台同步配置、SFTP 和团队协作功能。', '开发工具', '["ssh", "terminal", "devops"]', 'https://termius.com/favicon.ico', 'freemium', 0, '8.0.0', 'https://termius.com/download', 5400, 4.6, 1200, 'PUBLISHED', NOW() - INTERVAL '50 days', NOW() - INTERVAL '50 days', NOW()),
(9, 'chrome', 'Google Chrome', '快速、安全的网络浏览器', 'Google Chrome 是一款快速、易用且安全的网络浏览器，支持丰富的扩展程序和开发者工具。', '浏览器', '["browser", "google", "web"]', 'https://www.google.com/chrome/static/images/chrome-logo.svg', 'free', 0, '121.0', 'https://www.google.com/chrome/downloads', 25600, 4.5, 8900, 'PUBLISHED', NOW() - INTERVAL '130 days', NOW() - INTERVAL '130 days', NOW()),
(10, 'spotify', 'Spotify', '音乐流媒体服务', 'Spotify 是全球领先的音乐流媒体服务平台，提供数百万首歌曲和播客的在线播放和下载。', '娱乐', '["music", "streaming", "entertainment"]', 'https://developer.spotify.com/images/guidelines/design/icon.svg', 'freemium', 0, '1.2.0', 'https://www.spotify.com/download', 18900, 4.7, 6700, 'PUBLISHED', NOW() - INTERVAL '40 days', NOW() - INTERVAL '40 days', NOW()),
(11, 'slack', 'Slack', '团队沟通与协作平台', 'Slack 是一款团队沟通工具，支持频道、私信、文件共享和丰富的第三方应用集成。', '生产力', '["chat", "collaboration", "team"]', 'https://a.slack-edge.com/80588/marketing/img/icons/icon_slack_hash_colored.png', 'freemium', 0, '4.35.0', 'https://slack.com/downloads', 14300, 4.5, 4200, 'PUBLISHED', NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days', NOW()),
(12, 'git', 'Git', '分布式版本控制系统', 'Git 是一个免费的开源分布式版本控制系统，旨在快速高效地处理从小型到大型项目的所有内容。', '开发工具', '["vcs", "version-control", "scm"]', 'https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png', 'free', 0, '2.43.0', 'https://git-scm.com/downloads', 19800, 4.9, 5100, 'PUBLISHED', NOW() - INTERVAL '140 days', NOW() - INTERVAL '140 days', NOW());

-- 重置序列（让后续插入从 13 开始）
SELECT setval('app_store_apps_id_seq', 12, true);
