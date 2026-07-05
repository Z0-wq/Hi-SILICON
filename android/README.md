# 边缘智能体育助教平台

## 硬件平台
| 节点 | 芯片 | 角色 |
|------|------|------|
| 可穿戴端 | 海思 WS63E | ICM-42688 IMU采集 + SLE发送 |
| 网关端 | 海思 SS928 | SLE接收 + HTTP服务 :8080 |
| 客户端 | 跨平台 | Flutter APP展示与分析 |

## 开发环境
- WS63E：HiSpark Studio，工程路径 `e:/HiSpark/fbb_ws63/src`，C语言
- SS928：海思嵌入式SDK，C语言（sle_imu_client.c）
- Flutter：Dart，`flutter pub get && flutter run`

## 整体分层架构
```
WS63E (SLE Server)
  ↓ 星闪SLE，25字节包，50Hz，设备名 imu_node
SS928 sle_imu_client.c
  ↓ [TODO] socket/共享内存 → HTTP服务 :8080
Flutter APP (HTTP 500ms轮询 /api/imu/live)
  ↓ Provider + ChangeNotifier
UI：实时数据 / 波形图 / 跑姿分析 / 健身指导 / 历史记录
```

## 目录结构
```
sport_coach_app/
├── lib/                        # Flutter APP
│   ├── main.dart               # 入口 + 底部导航
│   ├── models/imu_data.dart    # ImuData / HistoryRecord
│   ├── providers/app_state.dart # 全局状态 + 500ms轮询
│   ├── services/api_service.dart # HTTP客户端
│   └── screens/                # 6个页面
├── ss928/sle_imu_client.c      # SS928 SLE接收端（C）
└── docs/                       # 协议文档 + PCB迁移指南
```

## 不可改动核心区域
- 25字节IMU数据包协议格式（见 rule.md）
- SLE回调注册流程（sle_imu_client.c `sle_imu_client_init`）
- Flutter Provider架构（app_state.dart）
- HTTP API路径：`GET /api/imu/live`、`GET /api/history`、`POST /api/history`
