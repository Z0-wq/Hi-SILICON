# 代码骨架接口清单

## SS928 — sle_imu_client.c

### 宏定义
```c
#define IMU_PACKET_LEN      25
#define IMU_HEADER          0xAA
#define SLE_IMU_SERVER_NAME "imu_node"
#define SLE_IMU_SERVER_ADDR {0x11,0x22,0x33,0x44,0x55,0x66}
#define SLE_MTU_SIZE        520
#define SLE_SEEK_INTERVAL   100
#define SLE_SEEK_WINDOW     100
#define SLE_CONN_INTERVAL   0x64
#define SLE_CONN_TIMEOUT    0x1F4
#define SLE_SCAN_INTERVAL   400
#define SLE_SCAN_WINDOW     20
#define IMU_CLIENT_TASK_PRIO   26
#define IMU_CLIENT_STACK_SIZE  0x2000
```

### 结构体
```c
typedef struct {
    uint8_t  header; uint8_t seq;
    int16_t  acc_x, acc_y, acc_z;
    int16_t  gyro_x, gyro_y, gyro_z;
    uint32_t timestamp;
    int16_t  roll_x100, pitch_x100;
    uint16_t count;
    uint8_t  checksum;
} __attribute__((packed)) imu_packet_t;  // 25字节
```

### 全局变量
```c
static sle_announce_seek_callbacks_t g_seek_cbk;
static sle_connection_callbacks_t    g_connect_cbk;
static ssapc_callbacks_t             g_ssapc_cbk;
static sle_addr_t                    g_remote_addr;
static uint16_t                      g_conn_id;
static ssapc_find_service_result_t   g_service;
```

### 函数清单
| 函数名 | 入参 | 返回 | 功能 |
|--------|------|------|------|
| `imu_verify_checksum` | `const uint8_t *buf` | `int` | 校验25字节包XOR |
| `imu_notification_cb` | client_id, conn_id, `ssapc_handle_value_t*`, status | void | 收到Notify，验证包，打印日志，**TODO传给HTTP** |
| `sle_enable_cbk` | `errcode_t status` | void | SLE使能后设本机地址、连接参数、启动扫描 |
| `seek_disable_cbk` | `errcode_t status` | void | 扫描停止后发起连接 |
| `seek_result_cbk` | `sle_seek_result_info_t*` | void | 匹配WS63E广播地址，停止扫描 |
| `connect_state_cbk` | conn_id, addr, conn_state, pair_state, disc_reason | void | 连接成功触发配对，断开重扫 |
| `pair_complete_cbk` | conn_id, addr, status | void | 配对完成后协商MTU |
| `exchange_info_cbk` | client_id, conn_id, `ssap_exchange_info_t*`, status | void | MTU协商完成后发现服务 |
| `find_structure_cbk` | client_id, conn_id, `ssapc_find_service_result_t*`, status | void | 记录服务handle范围 |
| `find_structure_cmp_cbk` | client_id, conn_id, result, status | void | 服务发现完成，write触发notify |
| `write_cfm_cbk` | client_id, conn_id, `ssapc_write_result_t*`, status | void | write确认后read进入notify模式 |
| `sle_imu_client_init` | void | `int` | 注册所有回调，调用enable_sle() |
| `sle_imu_client_entry` | void | void | 创建任务线程，优先级26，栈0x2000 |

---

## Flutter — lib/models/imu_data.dart

### 类
```dart
class ImuData {
  final int seq, accX, accY, accZ, gyroX, gyroY, gyroZ, timestamp, count;
  final double roll, pitch;
  factory ImuData.fromJson(Map<String,dynamic> j)
  static ImuData get mock  // 静态mock数据
}

class HistoryRecord {
  final String date, action;
  final int count;
  final double score;
  factory HistoryRecord.fromJson(Map<String,dynamic> j)
}
```

---

## Flutter — lib/services/api_service.dart

```dart
class ApiService {
  String baseUrl;
  ApiService(this.baseUrl)
  Future<ImuData?> fetchLiveData()          // GET /api/imu/live，2s超时
  Future<List<HistoryRecord>> fetchHistory() // GET /api/history，5s超时，失败返回mock
  Future<bool> saveHistory(HistoryRecord)    // POST /api/history，成功返回201
}
```

---

## Flutter — lib/providers/app_state.dart

```dart
class AppState extends ChangeNotifier {
  String _serverIp;        // 默认 192.168.1.100
  int _serverPort;         // 默认 8080
  bool _connected;
  ImuData _liveData;
  List<HistoryRecord> _history;
  List<ImuData> _chartBuffer;  // 50帧滚动缓冲
  Timer? _pollTimer;
  ApiService _api;

  Future<void> _loadSettings()              // 启动时加载SharedPreferences
  Future<void> saveSettings(String ip, int port)
  void _startPolling()                      // 500ms定时器轮询fetchLiveData
  Future<void> loadHistory()
}
```

---

## Flutter — lib/screens/

| 文件 | 关键逻辑 |
|------|---------|
| `home_screen.dart` | 4卡片：计数/姿态角/加速度/角速度；AppBar连接状态图标 |
| `chart_screen.dart` | fl_chart，3图表：acc/gyro/姿态角，50帧缓冲，范围±2000 |
| `running_screen.dart` | 跑姿评分：Pitch(5~15°)/Roll(<10°)/accZ振幅(<150mg)/冲击(<1500mg)，0~100分 |
| `fitness_screen.dart` | 5种动作教程（平板/深蹲/俯卧撑/瑜伽山式/瑜伽树式）+ IMU参考范围 |
| `history_screen.dart` | 按日期分组，评分颜色：≥90绿/75~90橙/<75红 |
| `settings_screen.dart` | IP+端口输入，SharedPreferences持久化 |
