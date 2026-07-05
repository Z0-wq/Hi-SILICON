/**
 * SS928 SLE IMU 接收端 — 伪代码骨架
 *
 * 🔴 [交成员1完成] 此文件需要基于 SS928 的 SLE SDK 实现。
 *    成员3已完成：协议定义、数据解析、文件写入逻辑。
 *    成员1需要：用 SS928 实际的 SLE API 替换标注 [SS928 API] 的部分。
 *
 * 运行环境：SS928 OpenEuler Linux 用户态
 * 编译方式：gcc -o sle_imu_client sle_imu_client.c -lpthread
 *           （根据SS928 SLE SDK实际情况添加 -l 参数）
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

/* ============================================================
 * 协议常量（与 WS63 sle_imu_server.c 完全一致，不可改动）
 * ============================================================ */
#define IMU_PACKET_LEN      23
#define IMU_HEADER          0xAA
#define SLE_SERVER_NAME     "imu_node"
#define SLE_MTU_SIZE        520

/* 方案A：双节点MAC区分，包格式不变 */
#define SLE_ADDR_ARM    {0x11, 0x22, 0x33, 0x44, 0x55, 0x66}  /* 上臂节点 */
#define SLE_ADDR_CHEST  {0x11, 0x22, 0x33, 0x44, 0x55, 0x67}  /* 胸前节点 */
#define SLE_LOCAL_ADDR  {0x13, 0x67, 0x5C, 0x07, 0x00, 0x52}  /* SS928本机 */

/* 节点ID */
#define NODE_ARM    0
#define NODE_CHEST  1
#define NODE_UNKNOWN 2

/* 23字节数据包结构（小端序，count已移除，由成员1视觉侧自行计数）*/
typedef struct {
    uint8_t  header;       /* 0xAA */
    uint8_t  seq;
    int16_t  acc_x;        /* mg */
    int16_t  acc_y;
    int16_t  acc_z;
    int16_t  gyro_x;       /* 0.1 dps */
    int16_t  gyro_y;
    int16_t  gyro_z;
    uint32_t timestamp;    /* ms */
    int16_t  roll_x100;    /* 横滚角×100 */
    int16_t  pitch_x100;   /* 俯仰角×100 */
    uint8_t  checksum;     /* 前22字节XOR */
} __attribute__((packed)) imu_packet_t;

/* ============================================================
 * 数据写入（成员3完成，不需要改动）
 * 收到IMU包后写 /tmp/imu_latest.txt，imu_receiver.py 读取
 * ============================================================ */
static int imu_verify_checksum(const uint8_t *buf)
{
    uint8_t calc = 0;
    for (int i = 0; i < IMU_PACKET_LEN - 1; i++) calc ^= buf[i];
    return (calc == buf[IMU_PACKET_LEN - 1]);
}

static void imu_on_packet_received(const uint8_t *raw, int len, int node_id)
{
    if (len != IMU_PACKET_LEN) return;
    if (raw[0] != IMU_HEADER) return;
    if (!imu_verify_checksum(raw)) {
        printf("[imu] checksum error, drop\n");
        return;
    }

    const imu_packet_t *pkt = (const imu_packet_t *)raw;
    const char *node_name = (node_id == NODE_ARM) ? "arm" : "chest";
    printf("[imu][%s] seq:%d acc(%d,%d,%d) gyro(%d,%d,%d) roll:%.2f pitch:%.2f\n",
        node_name,
        pkt->seq,
        pkt->acc_x, pkt->acc_y, pkt->acc_z,
        pkt->gyro_x, pkt->gyro_y, pkt->gyro_z,
        pkt->roll_x100 / 100.0f, pkt->pitch_x100 / 100.0f);

    /* 按节点写不同文件，imu_receiver.py 分别读取 */
    const char *path = (node_id == NODE_ARM)
        ? "/tmp/imu_arm.txt"
        : "/tmp/imu_chest.txt";
    FILE *fp = fopen(path, "w");
    if (fp != NULL) {
        fprintf(fp, "%d %d %d %d %d %d %d %u %d %d\n",
            pkt->seq,
            pkt->acc_x, pkt->acc_y, pkt->acc_z,
            pkt->gyro_x, pkt->gyro_y, pkt->gyro_z,
            pkt->timestamp,
            pkt->roll_x100, pkt->pitch_x100);
        fclose(fp);
    }
}

/* ============================================================
 * 🔴 以下部分需要成员1用 SS928 实际 SLE SDK 替换
 * ============================================================
 *
 * 成员1需要实现：
 * 1. 初始化 SS928 SLE 栈
 * 2. 扫描广播名为 "imu_node" 的设备（地址 11:22:33:44:55:66）
 * 3. 连接、配对、MTU协商（目标520字节）
 * 4. 发现服务（UUID 0x1234），开启 Notify（UUID 0x1235）
 * 5. 收到 Notify 数据时，调用 imu_on_packet_received(data, len)
 *
 * 参考：WS63端的 sle_imu_client.c（application/samples/peripheral/sle_imu_client/）
 *       逻辑完全一样，只是 API 名称换成 SS928 的。
 * ============================================================ */

/*
 * [SS928 API] 伪代码示例，实际API以SS928 SLE SDK文档为准：
 *
 * void ss928_sle_init() {
 *     // [SS928 API] 初始化SLE栈
 *     sle_init();
 *     sle_set_local_addr(SLE_LOCAL_ADDR);
 * }
 *
 * void ss928_sle_scan_and_connect() {
 *     // [SS928 API] 启动扫描
 *     sle_start_scan();
 *     // 扫描回调中匹配 SLE_SERVER_ADDR，找到后停止扫描并连接
 *     sle_connect(SLE_SERVER_ADDR);
 * }
 *
 * void ss928_sle_on_notify(uint8_t *data, int len) {
 *     // 收到Notify时调用此函数
 *     imu_on_packet_received(data, len);  // ← 这行不变
 * }
 */

int main(void)
{
    printf("[SS928 SLE Client] 启动\n");
    printf("[SS928 SLE Client] 🔴 需要成员1填入SS928 SLE SDK的实际调用\n");
    printf("[SS928 SLE Client] 目标：连接 imu_node，接收25字节IMU包，写 /tmp/imu_latest.txt\n");

    /* 🔴 [SS928 API] 成员1在此初始化SLE并启动接收循环 */

    /* 保活主线程 */
    while (1) sleep(1);
    return 0;
}
