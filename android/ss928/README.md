# SS928 服务端交接说明（成员3 → 成员1）

> 更新日期：2026-06-10

---

## 职责说明

- **成员3（我）主导**：所有代码已写好，你只需要在SS928上执行
- **成员1配合**：Wi-Fi AP配置、Python环境安装、代码部署、SLE SDK填写

---

## 文件清单

| 文件 | 状态 | 说明 |
|------|------|------|
| `imu_receiver.py` | ✅ 直接运行 | Flask后端，全部接口完成，端口8080 |
| `sle_imu_client.c` | 🔴 你来填 | 数据解析+写文件已完成，SLE连接部分待你填 |
| `web/index.html` | ✅ 直接用 | Web前端入口，3页 |
| `web/css/style.css` | ✅ 直接用 | 样式 |
| `web/js/app.js` | ✅ 直接用 | 前端逻辑，500ms轮询 |

---

## 数据流（最终架构）

```
WS63E(上臂) ──SLE──→ SS928
WS63E(胸前) ──SLE──→ sle_imu_client.c（你填）
                          ↓ 写 /tmp/imu_arm.txt + /tmp/imu_chest.txt
                     imu_receiver.py（Flask :8080）
                          ↓ serve静态文件 + /api/*
                     浏览器（手机/电脑，连SS928热点访问）
                     http://192.168.4.1:8080
```

## 23字节数据包格式（2026-06-11更新，count已移除）

```
偏移  长度  字段        说明
0     1    header     固定 0xAA
1     1    seq        序号 0~255循环
2     2    acc_x      加速度X，mg，小端
4     2    acc_y      加速度Y，mg，小端
6     2    acc_z      加速度Z，mg，小端
8     2    gyro_x     角速度X，0.1dps，小端
10    2    gyro_y     角速度Y，0.1dps，小端
12    2    gyro_z     角速度Z，0.1dps，小端
14    4    timestamp  时间戳ms，小端
18    2    roll_x100  横滚角×100，小端
20    2    pitch_x100 俯仰角×100，小端
22    1    checksum   前22字节XOR
```

**完整性三重验证：**
1. `data[0] == 0xAA`
2. `len == 23`
3. `data[0]^...^data[21] == data[22]`

**count字段已移除**：动作计数由SS928视觉侧自行实现，WS63E只提供原始IMU数据。

---

## 第一步：你需要做的事（按顺序）

### 1. 配置 Wi-Fi AP

在SS928上配置 hostapd + dnsmasq，让手机/电脑能连上：

```bash
# /etc/hostapd/hostapd.conf
interface=wlan0
ssid=SS928-Coach
hw_mode=g
channel=6
wpa=2
wpa_passphrase=coach2026
wpa_key_mgmt=WPA-PSK

# /etc/dnsmasq.conf（追加）
interface=wlan0
dhcp-range=192.168.4.10,192.168.4.50,12h
address=/#/192.168.4.1

# 启动
systemctl enable hostapd dnsmasq
systemctl start hostapd dnsmasq
```

SS928本机IP固定为 `192.168.4.1`。

### 2. 安装Python依赖

```bash
pip3 install flask flask-cors
```

### 3. 部署代码到SS928

把整个 `ss928/` 目录拷贝到SS928，例如放在 `~/sport_coach/`：

```bash
scp -r ss928/ user@SS928的IP:~/sport_coach/
```

### 4. 运行服务，验证Web平台

```bash
cd ~/sport_coach
python3 imu_receiver.py
```

手机连上 `SS928-Coach` 热点，浏览器访问 `http://192.168.4.1:8080`，
能看到三页Web平台（运动/数据/我的）就说明部署成功。

---

## 第二步：填写 SLE 接收程序

`sle_imu_client.c` 里标了 `🔴 [SS928 API]` 的地方，用SS928实际SLE SDK替换：

**目标：**
- 扫描广播名 `imu_node` 的设备
- 上臂节点地址：`{0x11,0x22,0x33,0x44,0x55,0x66}`
- 胸前节点地址：`{0x11,0x22,0x33,0x44,0x55,0x67}`
- 连接→配对→MTU协商(520字节)→发现服务(UUID 0x1234)→开启Notify(UUID 0x1235)
- 收到Notify时，判断来源地址，调用：

```c
// 上臂节点
imu_on_packet_received(data, len, NODE_ARM);

// 胸前节点
imu_on_packet_received(data, len, NODE_CHEST);
```

**数据解析和文件写入已全部实现，你只需要填SLE连接这一块。**

参考：WS63E端的 `sle_imu_client`（`application/samples/peripheral/sle_imu_client/`），
逻辑完全一样，只是API名称换成SS928的。

---

## 第三步：配置开机自启

创建两个 systemd 服务文件：

```bash
# /etc/systemd/system/sport-flask.service
[Unit]
Description=Sport Coach Flask Server
After=network.target

[Service]
WorkingDirectory=/home/user/sport_coach
ExecStart=/usr/bin/python3 imu_receiver.py
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable sport-flask
systemctl start sport-flask
```

AI推理进程（YOLOv11s-pose）同样方式配置，两个进程都开机自启。

---

## HTTP接口完整列表

| 接口 | 方法 | 说明 |
|------|------|------|
| `/` | GET | Web平台首页（index.html） |
| `/api/imu/live` | GET | 上臂节点最新一帧IMU数据 |
| `/api/imu/node/arm` | GET | 上臂节点数据 |
| `/api/imu/node/chest` | GET | 胸前节点数据 |
| `/api/history` | GET | 历史训练记录 `{records:[...], total:N}` |
| `/api/history` | POST | 保存记录 `{date,action,count,score}` |
| `/api/history/<index>` | DELETE | 删除指定记录 |
| `/api/mode` | GET/POST | 读写运动模式（pullup/pushup） |
| `/api/status` | GET | 连接状态+last_seq |
| `/api/save` | POST | WS63双击自动保存当前训练 |

---

## 联调时间节点

### 首次联调（W1末，6/15~6/16，约2小时，需成员3在场）

**前提条件（两个都满足才联调）：**
- SS928 Wi-Fi AP已跑通，手机能连上
- WS63E板子SLE已广播

**验证链路：**
```
WS63E上电 → SLE广播 → SS928接收 → /tmp/imu_arm.txt → Flask →
浏览器访问 192.168.4.1:8080 → 实时IMU波形动起来
```

### W2联调（6/16~6/22，全员）
- 多模态融合：视觉计数 + IMU计数对齐
- 模式切换：按WS63E按键，Web平台模式同步切换

---

## 注意事项

- 端口固定 **8080**，不要改
- WS63E广播地址不可改（`0x66`=上臂，`0x67`=胸前）
- SLE回调内**禁止阻塞操作**（会NMI崩溃）
- `imu_on_packet_received` 函数不要改，只填SLE连接部分
