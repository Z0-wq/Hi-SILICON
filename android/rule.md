# 硬件与代码硬性规约

## 固定引脚（WS63E 开发板）
| 信号 | 开发板GPIO | 自研PCB GPIO |
|------|-----------|-------------|
| SPI MOSI | 9 | 12 |
| SPI CLK | 7 | 14 |
| SPI MISO | 11 | 13 |
| SPI CS | 10 | 11 |
| SPI PIN_MODE | 3（不变） | 3（不变） |

修改方式：仅改 `application/samples/peripheral/icm42688_spi/Kconfig` 的 default 值，不改其他文件。

## SLE通信协议参数（不可改动）
| 参数 | 值 |
|------|-----|
| 设备名 | `imu_node` |
| Service UUID | `0x1234` |
| Property UUID | `0x1235`（Notify） |
| MTU | 520字节 |
| 连接间隔 | `0x64`（SLE_CONN_INTERVAL） |
| 连接超时 | `0x1F4` |
| 扫描间隔/窗口 | 400 / 20 |
| WS63E广播地址 | `{0x11,0x22,0x33,0x44,0x55,0x66}` |
| SS928本机地址 | `{0x13,0x67,0x5C,0x07,0x00,0x52}` |

## 25字节IMU数据包格式（不可改动）
```
偏移  长度  字段         类型        说明
0     1    header       uint8_t     固定 0xAA
1     1    seq          uint8_t     包序号循环 0~255
2     2    acc_x        int16_t LE  加速度X，单位mg
4     2    acc_y        int16_t LE  加速度Y，单位mg
6     2    acc_z        int16_t LE  加速度Z，单位mg
8     2    gyro_x       int16_t LE  角速度X，单位0.1dps
10    2    gyro_y       int16_t LE  角速度Y，单位0.1dps
12    2    gyro_z       int16_t LE  角速度Z，单位0.1dps
14    4    timestamp    uint32_t LE 时间戳ms
18    2    roll_x100    int16_t LE  横滚角×100
20    2    pitch_x100   int16_t LE  俯仰角×100
22    2    count        uint16_t LE 动作计数
24    1    checksum     uint8_t     前24字节XOR
```
- 采样率：50Hz（20ms/包）
- 加速度量程：±2g；陀螺仪量程：±2000dps
- 校验：`uint8_t c=0; for(i=0;i<24;i++) c^=buf[i];`

## HTTP API规约（不可改动）
- `GET /api/imu/live` → 返回最新一帧JSON，字段：seq/acc_x/acc_y/acc_z/gyro_x/gyro_y/gyro_z/timestamp/roll/pitch/count/recv_time
- `GET /api/history` → 返回JSON数组，每项：date/action/count/score
- `POST /api/history` → body JSON：date/action/count/score，成功返回201
- 服务端口：8080

## 编码规范
- C代码：`__attribute__((packed))` 保证结构体无填充
- 多字节字段全部小端序（Little-Endian）
- Flutter：Provider + ChangeNotifier，禁止在Widget内直接持有Timer
- 轮询间隔：500ms，不可随意调整（影响波形图50帧缓冲节奏）

## 禁止写法
- 禁止修改 `imu_packet_t` 结构体字段顺序或类型
- 禁止在SLE回调中做阻塞操作
- 禁止在Flutter中绕过AppState直接调用ApiService
- 禁止改动 `SLE_IMU_SERVER_ADDR` 和 `SLE_IMU_SERVER_NAME` 宏（与WS63E固件强绑定）
