# First Boot Guide (New Mac)

适用于第一次在新 Mac 上把 `mac-vibe-bootstrap` 跑通。

## 0) 前置条件

- 使用**可交互终端**（能输入 sudo 密码）
- 网络正常（可访问 Homebrew/GitHub/npm）
- 建议接电源

## 1) 克隆仓库

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/Palebluedot-ai/mac-vibe-bootstrap.git
cd mac-vibe-bootstrap
```

## 2) 先跑必选

```bash
bash bootstrap.sh --required
```

这一步会完成：
- Xcode CLT / Homebrew
- 核心 CLI
- Python + uv
- Node(FNM) + npm 全局工具
- Claude/Codex 可执行检查
- 系统稳定性模块（含防睡眠配置尝试）
- required checklist 核验

## 3) 再跑可选

```bash
bash bootstrap.sh --optional
```

这一步会完成：
- 扩展工具与应用
- optional checklist 核验

## 4) 一次性校验

```bash
bash bootstrap.sh --only checklist
```

## 5) 建议立即执行的升级

```bash
bash bootstrap.sh --update
```

---

## 常见问题与恢复

### A. 提示 `No sudo TTY` / `sudo: a terminal is required`
你是在无交互环境执行。请在本机终端重新执行：

```bash
cd ~/projects/mac-vibe-bootstrap
bash bootstrap.sh --required
```

并确保能输入 sudo 密码。

### B. Docker Desktop 安装失败（/usr/local/cli-plugins 权限）
本机终端手动执行：

```bash
brew install --cask docker
```

### C. `python3` 仍显示系统旧版本
临时：

```bash
/opt/homebrew/bin/python3 --version
```

建议把 Homebrew bin 放到 PATH 前面（zsh）：

```bash
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
python3 --version
```

### D. fnm 初始化后 node 不生效

```bash
source ~/.zshrc
fnm install --lts
fnm default lts-latest
node -v
```

### E. 登录项 AppleScript 超时（System Events timed out）
这不影响主流程。可在系统设置手动加：
- Stats
- KeepingYouAwake
- AlDente

路径：系统设置 → 通用 → 登录项。

### F. 想恢复电源默认策略

```bash
bash scripts/30-system-stability.sh --restore
```

### G. 查看当前电源状态

```bash
bash scripts/30-system-stability.sh --status
```

---

## 推荐首跑顺序（最稳）

```bash
bash bootstrap.sh --required
bash bootstrap.sh --optional
bash bootstrap.sh --only checklist
bash bootstrap.sh --update
```

如果 checklist 失败，直接按日志中的 missing 项补装后重跑 checklist 即可。
