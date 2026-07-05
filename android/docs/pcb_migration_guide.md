# 固件移植指南：开发板 → 自研 PCB

## 需要修改的唯一文件

只需修改一个文件：
`application/samples/peripheral/icm42688_spi/Kconfig`

## 引脚对照表

| 信号 | 开发板（当前） | 自研 PCB |
|------|--------------|---------|
| SPI MOSI | GPIO 9 | GPIO 12 |
| SPI CLK  | GPIO 7 | GPIO 14 |
| SPI MISO | GPIO 11 | GPIO 13 |
| SPI CS   | GPIO 10 | GPIO 11 |

## 修改方法

将 `Kconfig` 中的 default 值改为自研 PCB 的引脚编号：

```diff
 config ICM42688_SPI_MOSI_PIN
-    default 9
+    default 12

 config ICM42688_SPI_CLK_PIN
-    default 7
+    default 14

 config ICM42688_SPI_MISO_PIN
-    default 11
+    default 13

 config ICM42688_SPI_CS_PIN
-    default 10
+    default 11
```

`ICM42688_SPI_PIN_MODE` 保持 `default 3` 不变。

## 编译烧录步骤

```bash
# 1. 进入工程根目录
cd e:/HiSpark/fbb_ws63

# 2. 清理旧编译产物（引脚改了必须重新编译）
rm -rf build/

# 3. 编译
python build.py fbb_ws63 -b

# 4. 烧录（串口工具 HiBurn 或 hiburn.exe）
# 选择 build/fbb_ws63/fbb_ws63.bin，波特率 115200
```

## 验证方法

烧录后打开串口（115200），观察日志：

**正常输出（ICM 识别成功）：**
```
[ICM42688] WHO_AM_I = 0x47, OK
[ICM42688] gyro calib done: bx=xx by=xx bz=xx
imu attitude: roll=xx.xxdeg pitch=xx.xxdeg count=0
```

**异常输出（引脚接错）：**
```
[ICM42688] WHO_AM_I = 0x00, expected 0x47
```
→ 检查 PCB 焊接和引脚定义是否正确

## SLE 发送端无需修改

`sle_imu_server.c` 和 `sle_imu_server.h` 不依赖 GPIO，PCB 到货后直接可用。
