# Green MVP Foundation

- 离线优先：MVP 阶段不接 API，不接后端。
- 数据存储：CoreData。
- 照片管理：PhotoKit，后续同时覆盖完整访问与部分访问。
- 动画生成：AVFoundation，导出任务必须放后台线程。
- 通知：UserNotifications，后续在正式提醒阶段接入首次启动授权。
- 本地健康检测：Vision Framework，本地模型优先。
- 开发顺序固定：
  1. 植物档案 CRUD
  2. 照片记录 + PhotoKit
  3. 浇水提醒 + 通知
  4. 成长动画生成
  5. FAB 快捷入口
