# IMU 数据协议文档

## 概述
WS63E 可穿戴节点通过星闪 SLE 协议向 SS928 发送 IMU 数据包，SS928 需要实现 SLE Client 接收端。

## 通信架构
```
WS63E (SLE Server)  --星闪-->  SS928 (SLE Client)  --Wi-Fi HTTP-->  Flutter APP
```

## SLE 连接参数
- **设备名称**: `imu_node`
- **Service UUID**: `0x1234`
- **Property UUID**: `0x1235` (Notify)
- **MTU**: 520 字节
- **连接间隔**: 12.5ms
- **广播间隔**: 25ms

## 数据包格式

### imu_packet_t 结构体

```c
typedef struct {
    uint8_t  header;      // 固定 0xAA，帧头
    uint8_t  seq;         // 包序号，uint8_t 循环递增 (0~255)
    int16_t  acc_x;       // X轴加速度，单位 mg (1g = 1000mg)
    int16_t  acc_y;       // Y轴加速度，单位 mg
    int16_t  acc_z;       // Z轴加速度，单位 mg
    int16_t  gyro_x;      // X轴角速度，单位 0.1 dps (实际值 = gyro_x / 10.0)
    int16_t  gyro_y;      // Y轴角速度，单位 0.1 dps
    int16_t  gyro_z;      // Z轴角速度，单位 0.1 dps
    uint32_t timestamp;   // WS63E 本地时间戳，单位 ms
    int16_t  roll_x100;   // 横滚角 × 100（实际值 = roll_x100 / 100.0，单位度）
    int16_t  pitch_x100;  // 俯仰角 × 100（实际值 = pitch_x100 / 100.0，单位度）
    uint16_t count;       // 动作计数（WS63E 端峰值检测结果）
    uint8_t  checksum;    // 前24字节逐字节 XOR 校验
} __attribute__((packed)) imu_packet_t;  // 总计 25 字节
```

### 字节布局

| 偏移 | 长度 | 字段 | 类型 | 说明 |
|------|------|------|------|------|
| 0 | 1 | header | uint8_t | 固定 0xAA |
| 1 | 1 | seq | uint8_t | 包序号 |
| 2 | 2 | acc_x | int16_t LE | X轴加速度 mg |
| 4 | 2 | acc_y | int16_t LE | Y轴加速度 mg |
| 6 | 2 | acc_z | int16_t LE | Z轴加速度 mg |
| 8 | 2 | gyro_x | int16_t LE | X轴角速度 0.1dps |
| 10 | 2 | gyro_y | int16_t LE | Y轴角速度 0.1dps |
| 12 | 2 | gyro_z | int16_t LE | Z轴角速度 0.1dps |
| 14 | 4 | timestamp | uint32_t LE | 时间戳 ms |
| 18 | 2 | roll_x100 | int16_t LE | 横滚角 × 100 |
| 20 | 2 | pitch_x100 | int16_t LE | 俯仰角 × 100 |
| 22 | 2 | count | uint16_t LE | 动作计数 |
| 24 | 1 | checksum | uint8_t | 前24字节 XOR |

> 所有多字节字段均为**小端序 (Little-Endian)**

### 校验算法
```c
uint8_t checksum = 0;
for (int i = 0; i < 24; i++) checksum ^= ((uint8_t*)packet)[i];
```

## 采样参数
- **采样频率**: 50 Hz（每 20ms 一包）
- **加速度量程**: ±2g（ICM-42688 配置）
- **陀螺仪量程**: ±2000 dps

## SS928 接收端需要实现的 HTTP 接口

SS928 收到 SLE 数据后，需要提供以下 HTTP 接口供 Flutter APP 调用：

### GET /api/imu/live
返回最新一帧 IMU 数据（JSON）：
```json
{
  "seq": 123,
  "acc_x": -375,
  "acc_y": 500,
  "acc_z": 980,
  "gyro_x": 12,
  "gyro_y": -8,
  "gyro_z": 3,
  "timestamp": 12345,
  "roll": 27.5,
  "pitch": 3.2,
  "count": 42,
  "recv_time": 1714012345.678
}
```

字段说明：
- `acc_x/y/z`: 加速度，单位 mg
- `gyro_x/y/z`: 角速度，单位 0.1 dps
- `roll`: 横滚角，单位度（= roll_x100 / 100.0）
- `pitch`: 俯仰角，单位度（= pitch_x100 / 100.0）
- `count`: 动作计数

### GET /api/history
返回历史训练记录（JSON 数组）：
```json
[
  {"date": "2026-04-25", "action": "仰卧起坐", "count": 42, "score": 95.0},
  {"date": "2026-04-25", "action": "深蹲", "count": 30, "score": 88.0}
]
```

## SLE Client 参考实现（SS928 Python）

```python
import struct

PACKET_LEN  = 25
PACKET_FMT  = '<BBhhhhhhIhhHB'
# BB(2) + h*6(12) + I(4) + h*2(4) + H(2) + B(1) = 25字节

def parse_imu_packet(data: bytes):
    if len(data) != PACKET_LEN or data[0] != 0xAA:
        return None
    checksum = 0
    for b in data[:24]:
        checksum ^= b
    if checksum != data[24]:
        return None
    (_, seq, ax, ay, az, gx, gy, gz, ts,
     roll_x100, pitch_x100, count, _) = struct.unpack(PACKET_FMT, data)
    return {
        'seq': seq,
        'acc_x': ax, 'acc_y': ay, 'acc_z': az,
        'gyro_x': gx, 'gyro_y': gy, 'gyro_z': gz,
        'timestamp': ts,
        'roll':  roll_x100 / 100.0,
        'pitch': pitch_x100 / 100.0,
        'count': count,
    }
```

> **注意**: SS928 端 SLE Client 扫描时匹配设备名 `imu_node`，Service UUID `0x1234`，订阅 Property UUID `0x1235` 的 Notify。
