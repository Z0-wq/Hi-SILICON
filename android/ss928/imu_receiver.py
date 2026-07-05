"""
SS928 IMU 接收端参考代码
功能：通过星闪 SLE 接收 WS63E 发来的 25 字节 IMU 数据包，
      解析后通过 HTTP 接口提供给 Flutter APP。

依赖：
    pip install bleak flask

用法：
    python imu_receiver.py

注意：bleak 在 Linux/Windows 上均可用，但星闪 SLE 需要系统支持 NearLink。
      若 SS928 使用专有 SLE SDK，请将 BLE 部分替换为对应 SDK 的 API。
"""

import asyncio
import os
import sqlite3
import struct
import threading
import time
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS

# Web静态文件目录（相对于本脚本所在路径）
WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'web')
DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'training.db')

# ─── 协议常量 ────────────────────────────────────────────────────────────────
PACKET_LEN   = 23
HEADER_BYTE  = 0xAA
DEVICE_NAME  = "imu_node"

# 23字节布局（little-endian，count已移除）：
#   header(1) seq(1) acc_x(2) acc_y(2) acc_z(2)
#   gyro_x(2) gyro_y(2) gyro_z(2) timestamp(4)
#   roll_x100(2) pitch_x100(2) checksum(1)
# struct.calcsize('<BBhhhhhhIhhB') == 23
PACKET_FMT = "<BBhhhhhhIhhB"

# ─── 数据缓冲 ─────────────────────────────────────────────────────────────────
_latest_arm:   dict = {}   # 上臂节点最新一帧
_latest_chest: dict = {}   # 胸前节点最新一帧
_current_mode: str  = "pullup"
_mock_count:   int  = 0
_lock = threading.Lock()

# ─── SQLite 持久化 ────────────────────────────────────────────────────────────
def _db_init():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS records (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            date           TEXT,
            action         TEXT,
            count          INTEGER,
            score          REAL,
            duration_secs  INTEGER DEFAULT 0,
            frequency      REAL    DEFAULT 0,
            calories       REAL    DEFAULT 0,
            posture_issues TEXT    DEFAULT '[]',
            suggestions    TEXT    DEFAULT '[]'
        )
    """)
    conn.commit()
    conn.close()

def _db_insert(record: dict):
    import json
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        INSERT INTO records
            (date, action, count, score, duration_secs, frequency, calories, posture_issues, suggestions)
        VALUES (?,?,?,?,?,?,?,?,?)
    """, (
        record["date"], record["action"], record["count"], record["score"],
        record.get("duration_secs", 0), record.get("frequency", 0.0),
        record.get("calories", 0.0),
        json.dumps(record.get("posture_issues", []), ensure_ascii=False),
        json.dumps(record.get("suggestions", []), ensure_ascii=False),
    ))
    conn.commit()
    conn.close()

def _db_all() -> list:
    import json
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute(
        "SELECT id,date,action,count,score,duration_secs,frequency,calories,posture_issues,suggestions "
        "FROM records ORDER BY id ASC"
    ).fetchall()
    conn.close()
    return [{
        "id": r[0], "date": r[1], "action": r[2], "count": r[3], "score": r[4],
        "duration_secs": r[5], "frequency": r[6], "calories": r[7],
        "posture_issues": json.loads(r[8]), "suggestions": json.loads(r[9]),
    } for r in rows]

def _db_delete(record_id: int) -> bool:
    conn = sqlite3.connect(DB_PATH)
    cur = conn.execute("DELETE FROM records WHERE id=?", (record_id,))
    conn.commit()
    conn.close()
    return cur.rowcount > 0

_db_init()

# ─── 校验 ─────────────────────────────────────────────────────────────────────
def _verify_checksum(raw: bytes) -> bool:
    """前 24 字节 XOR 应等于第 25 字节"""
    calc = 0
    for b in raw[:24]:
        calc ^= b
    return calc == raw[24]

# ─── 解析 ─────────────────────────────────────────────────────────────────────
def parse_packet(raw: bytes) -> dict | None:
    if len(raw) != PACKET_LEN:
        return None
    if raw[0] != HEADER_BYTE:
        return None
    if not _verify_checksum(raw):
        return None

    fields = struct.unpack(PACKET_FMT, raw)
    (header, seq,
     acc_x, acc_y, acc_z,
     gyro_x, gyro_y, gyro_z,
     timestamp,
     roll_x100, pitch_x100,
     checksum) = fields

    return {
        "seq":       seq,
        "acc_x":     acc_x,
        "acc_y":     acc_y,
        "acc_z":     acc_z,
        "gyro_x":    gyro_x,
        "gyro_y":    gyro_y,
        "gyro_z":    gyro_z,
        "timestamp": timestamp,
        "roll":      roll_x100 / 100.0,
        "pitch":     pitch_x100 / 100.0,
        "recv_time": time.time(),
    }

# ─── SLE 接收（bleak 示例，实际替换为 SS928 SLE SDK）────────────────────────
try:
    from bleak import BleakScanner, BleakClient

    # 星闪 Notify UUID（与 WS63E sle_imu_server.c 中 SLE_UUID_NTF_REPORT 对应）
    NOTIFY_UUID = "00001235-0000-1000-b720-000000000000"

    def _on_notify(_sender, data: bytearray):
        pkt = parse_packet(bytes(data))
        if pkt is None:
            return
        with _lock:
            _latest_arm.update(pkt)

    async def _sle_loop():
        print(f"[SLE] 扫描设备 '{DEVICE_NAME}' ...")
        while True:
            device = await BleakScanner.find_device_by_name(DEVICE_NAME, timeout=10.0)
            if device is None:
                print("[SLE] 未找到设备，5秒后重试")
                await asyncio.sleep(5)
                continue
            print(f"[SLE] 找到设备 {device.address}，连接中...")
            try:
                async with BleakClient(device) as client:
                    await client.start_notify(NOTIFY_UUID, _on_notify)
                    print("[SLE] 已连接，开始接收数据")
                    while client.is_connected:
                        await asyncio.sleep(1)
            except Exception as e:
                print(f"[SLE] 连接断开: {e}，3秒后重连")
                await asyncio.sleep(3)

    def start_sle_thread():
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        loop.run_until_complete(_sle_loop())

except ImportError:
    print("[警告] bleak 未安装，尝试读取 /tmp/imu_arm.txt / /tmp/imu_chest.txt（SS928 C程序写入）")
    print("       若文件不存在则使用正弦波Mock数据")

    def _read_imu_file(path):
        """读取C程序写入的IMU文件，返回dict或None"""
        import os
        if not os.path.exists(path):
            return None
        try:
            with open(path, "r") as f:
                parts = f.read().strip().split()
            if len(parts) != 10:
                return None
            return {
                "seq":       int(parts[0]),
                "acc_x":     int(parts[1]),
                "acc_y":     int(parts[2]),
                "acc_z":     int(parts[3]),
                "gyro_x":    int(parts[4]),
                "gyro_y":    int(parts[5]),
                "gyro_z":    int(parts[6]),
                "timestamp": int(parts[7]),
                "roll":      int(parts[8]) / 100.0,
                "pitch":     int(parts[9]) / 100.0,
                "recv_time": time.time(),
            }
        except Exception as e:
            print(f"[警告] 读取{path}失败: {e}")
            return None

    def start_sle_thread():
        """
        两种模式自动切换：
        1. /tmp/imu_arm.txt 存在 → 读取 sle_imu_client.c 写入的真实数据
        2. 文件不存在 → 正弦波Mock数据（纯调试用）
        🔴 [SS928部署点] SS928上跑时，C程序持续写双节点文件，自动走模式1
        """
        global _mock_count
        import math
        seq = 0
        while True:
            t = time.time()
            arm_pkt   = _read_imu_file("/tmp/imu_arm.txt")
            chest_pkt = _read_imu_file("/tmp/imu_chest.txt")

            if arm_pkt is not None:
                with _lock:
                    _latest_arm.update(arm_pkt)
                if chest_pkt is not None:
                    with _lock:
                        _latest_chest.update(chest_pkt)
            else:
                # Mock数据（上臂节点）
                _mock_count += 1 if seq % 100 == 0 else 0
                pkt = {
                    "seq":       seq & 0xFF,
                    "acc_x":     int(math.sin(t) * 200),
                    "acc_y":     int(math.cos(t) * 150),
                    "acc_z":     1000,
                    "gyro_x":    int(math.sin(t * 2) * 300),
                    "gyro_y":    int(math.cos(t * 2) * 200),
                    "gyro_z":    50,
                    "timestamp": int(t * 1000) & 0xFFFFFFFF,
                    "roll":      round(math.sin(t) * 15, 2),
                    "pitch":     round(math.cos(t) * 10, 2),
                    "recv_time": t,
                }
                with _lock:
                    _latest_arm.update(pkt)
                seq += 1

            time.sleep(0.02)

# ─── HTTP 服务 ────────────────────────────────────────────────────────────────
app = Flask(__name__)
CORS(app)  # 允许跨域访问

@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response

# ─── 静态文件（Web平台前端）─────────────────────────────────────────────────
@app.route('/')
def index():
    return send_from_directory(WEB_DIR, 'index.html')

@app.route('/<path:filename>')
def static_files(filename):
    return send_from_directory(WEB_DIR, filename)

@app.route("/api/imu/live", methods=["GET", "OPTIONS"])
def api_live():
    """Web前端轮询，返回上臂节点（主节点）最新一帧"""
    with _lock:
        if not _latest_arm:
            return jsonify({"error": "no_data"}), 503
        return jsonify(_latest_arm)

@app.route("/api/imu/node/<node>", methods=["GET"])
def api_imu_node(node):
    """按节点查询，node=arm|chest，供多模态融合使用"""
    with _lock:
        if node == "arm":
            data = dict(_latest_arm)
        elif node == "chest":
            data = dict(_latest_chest)
        else:
            return jsonify({"error": "invalid_node"}), 400
    if not data:
        return jsonify({"error": "no_data"}), 503
    return jsonify(data)

@app.route("/api/history", methods=["GET"])
def api_history():
    records = _db_all()
    return jsonify({"records": records, "total": len(records)})

@app.route("/api/history", methods=["POST"])
def api_history_save():
    body = request.get_json(silent=True, force=True)
    if not body or not all(k in body for k in ("date", "action", "count", "score")):
        return jsonify({"error": "invalid_body"}), 400
    record = {
        "date":          str(body["date"]),
        "action":        str(body["action"]),
        "count":         int(body["count"]),
        "score":         float(body["score"]),
        "duration_secs": int(body.get("duration_secs", 0)),
        "frequency":     float(body.get("frequency", 0.0)),
        "calories":      float(body.get("calories", 0.0)),
        "posture_issues": list(body.get("posture_issues", [])),
        "suggestions":   list(body.get("suggestions", [])),
    }
    _db_insert(record)
    return jsonify({"ok": True}), 201

@app.route("/api/history/<int:record_id>", methods=["DELETE"])
def api_history_delete(record_id):
    if _db_delete(record_id):
        return jsonify({"ok": True}), 200
    return jsonify({"error": "not_found"}), 404

@app.route("/api/status")
def api_status():
    with _lock:
        connected = bool(_latest_arm)
        last_seq  = _latest_arm.get("seq", -1)
    return jsonify({"connected": connected, "last_seq": last_seq})

@app.route("/api/mode", methods=["GET"])
def api_mode_get():
    """获取当前运动模式"""
    with _lock:
        mode = _current_mode
    return jsonify({"mode": mode})

@app.route("/api/mode", methods=["POST"])
def api_mode_set():
    """
    设置运动模式，body: {"mode": "pullup"} 或 {"mode": "pushup"}
    🔴 [SS928部署点] 成员1需要在此处把模式命令通过SLE下行发给WS63
    """
    global _current_mode
    body = request.get_json(silent=True)
    if not body or "mode" not in body:
        return jsonify({"error": "invalid_body"}), 400
    mode = body["mode"]
    if mode not in ("pullup", "pushup"):
        return jsonify({"error": "invalid_mode"}), 400
    global _mock_count
    with _lock:
        _current_mode = mode
        _mock_count = 0  # 切换模式时计数归零
    print(f"[MODE] 切换到: {mode}")
    # 🔴 [SS928部署点] 成员1在此处调用SS928 SLE下行API，把mode命令发给WS63
    return jsonify({"ok": True, "mode": mode})

@app.route("/api/save", methods=["POST"])
def api_save():
    """
    WS63双击按键触发：自动保存当前训练记录
    🔴 [SS928部署点] 成员1在sle_imu_client.c收到0x20命令时调用此接口
    """
    with _lock:
        count = _latest_arm.get("count", 0)
        mode  = _current_mode
    if count == 0:
        return jsonify({"error": "no_count"}), 400
    score = min(min(count * 5.0, 70.0) + 30.0, 100.0)
    from datetime import datetime
    record = {
        "date":   datetime.now().strftime("%Y-%m-%d"),
        "action": "引体向上" if mode == "pullup" else "俯卧撑",
        "count":  count,
        "score":  round(score, 1),
    }
    _db_insert(record)
    print(f"[SAVE] 已保存: {record}")
    return jsonify({"ok": True, "record": record}), 201

# ─── 入口 ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    t = threading.Thread(target=start_sle_thread, daemon=True)
    t.start()
    print("[HTTP] 启动 HTTP 服务 http://0.0.0.0:8080")
    print("[HTTP] 接口列表:")
    print("  GET  /api/imu/live    — 实时IMU数据")
    print("  GET  /api/history     — 历史记录")
    print("  POST /api/history     — 保存历史记录")
    print("  GET  /api/mode        — 获取当前模式")
    print("  POST /api/mode        — 切换运动模式")
    print("  GET  /api/status      — 连接状态")
    app.run(host="0.0.0.0", port=8080, debug=False, use_reloader=False)
