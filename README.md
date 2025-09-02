# 🛠️ auto-mount-disk-safe

> 安全、可靠、可模拟的 Linux 磁盘自动挂载脚本 —— **安全完全体之最终版 v5.0**

一键解决数据盘挂载混乱问题，支持模拟执行、强制继续、依赖检查、fstab 备份、读写测试，适合生产环境使用。

---

## 🌟 特性

- ✅ `dry-run` 模式：模拟执行，不修改系统
- ✅ `--force` 模式：强制继续，用于验证流程
- ✅ `--help` 支持：用户友好，开箱即用
- ✅ 自动清理重复挂载点
- ✅ 自动备份 `/etc/fstab`
- ✅ 使用 UUID 永久挂载
- ✅ 开机自启兼容（支持 systemd）
- ✅ 读写测试，验证挂载可用性
- ✅ 彩色日志，清晰易读

---

## 🚀 快速使用

```bash
# 下载脚本
curl -sLO https://github.com/syh0304/auto-mount-disk-safe/blob/main/auto-mount-disk-safe.sh

# 添加执行权限
chmod +x auto-mount-disk-safe.sh

# 模拟执行（推荐先测试）
sudo ./auto-mount-disk-safe.sh dry-run

# 强制模拟（验证全流程）
sudo ./auto-mount-disk-safe.sh dry-run --force

# 正式执行
sudo ./auto-mount-disk-safe.sh
