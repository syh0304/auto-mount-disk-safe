# systemd 开机自启配置说明

本指南教你如何将 `auto-mount-disk-safe.sh` 设置为系统服务，实现 **开机自动挂载数据盘**。

适用于：Ubuntu、Debian、CentOS、Rocky Linux 等使用 `systemd` 的 Linux 发行版。

---

## 🔧 步骤 1：将脚本复制到系统目录

```bash
sudo cp auto-mount-disk-safe.sh /usr/local/bin/auto-mount-disk-safe
sudo chmod +x /usr/local/bin/auto-mount-disk-safe


步骤 2：创建 systemd 服务文件

sudo tee /etc/systemd/system/mount-disk.service << 'EOF'
[Unit]
Description=Auto Mount Data Disk - Safe Mode
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-mount-disk-safe
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

步骤 3：启用服务

# 重新加载 systemd 配置
sudo systemctl daemon-reload

# 启用开机自启
sudo systemctl enable mount-disk.service

# 立即启动服务（测试）
sudo systemctl start mount-disk.service

# 查看状态
sudo systemctl status mount-disk.service

# 查看日志
sudo journalctl -u mount-disk.service -n 50 --no-pager

验证是否成功

mount | grep /mnt/workspace