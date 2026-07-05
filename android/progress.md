# 开发进度

## 已完成
- WS63E 固件：ICM-42688 SPI采集 + 互补滤波 + 峰值计数 + SLE发送（50Hz，25字节）
- SS928 SLE接收端：`sle_imu_client.c` 完成SLE连接/配对/服务发现/Notify接收，校验和验证
- Flutter APP：全部6个页面（实时数据/波形图/跑姿分析/健身指导/历史记录/设置）
- HTTP API定义：`/api/imu/live`、`/api/history`（GET/POST）
- PCB迁移文档：GPIO引脚对照表已整理

## 当前问题
- SS928 `sle_imu_client.c` 第98行 TODO：收到IMU数据后尚未实现向上层HTTP服务传递（socket/共享内存方案未定）
- SS928 HTTP服务端（imu_receiver）尚未实现C语言版本，目前README中描述的是Python版本

## 现存BUG
- 无已知BUG（Flutter APP使用mock数据可正常运行）

## 待开发任务
- [ ] SS928：实现数据上传通道（socket或共享内存），将 `imu_packet_t` 传给HTTP服务
- [ ] SS928：实现HTTP服务端（C语言，响应 `/api/imu/live` 和 `/api/history`）
- [ ] WS63E：PCB到货后修改Kconfig GPIO引脚（参考 docs/pcb_migration_guide.md）
- [ ] Flutter：跑姿分析评分算法与实际IMU数据联调验证

## 临时搁置
- 算法/模型部分（成员2负责，接口待对接）
