# mac-vibe-bootstrap

新 Mac 的 Vibe Coding 一键配置脚本（两段式：必选 / 可选）。

## 目标
- **可重复执行**：已安装自动跳过
- **可升级判断**：通过 `brew outdated` / 版本检测
- **单入口执行**：只需要跑 `bootstrap.sh`

## 目录
- `bootstrap.sh`：主入口
- `scripts/00-preflight.sh`：系统预检
- `scripts/10-required.sh`：必选安装
- `scripts/20-optional.sh`：可选安装
- `scripts/70-post-check.sh`：安装后健康检查
- `scripts/80-update-all.sh`：统一升级
- `config/brew/*.required|optional`：Brewfile 清单
- `config/npm/*`：npm 全局包清单
- `config/python/*`：Python 工具清单

## 使用
```bash
cd ~/projects/mac-vibe-bootstrap
bash bootstrap.sh
```

### 仅安装必选
```bash
bash bootstrap.sh --required
```

### 仅安装可选
```bash
bash bootstrap.sh --optional
```

### 仅更新
```bash
bash bootstrap.sh --update
```

### 仅跑某模块
```bash
bash bootstrap.sh --only required
```

### 跳过某模块
```bash
bash bootstrap.sh --skip optional
```

### 预演（不执行）
```bash
bash bootstrap.sh --dry-run
```

## 必选包含
- Xcode CLT / Xcode 首次初始化
- Homebrew + 核心 CLI 工具
- Python3 + uv
- Node.js（FNM 管理）+ npm/pnpm
- Claude Code CLI / Codex CLI
- Warp / Chrome / VSCode / Obsidian

## 版本与升级判断
- 已安装判断：`command -v`、`brew list`、`brew list --cask`
- 可升级判断：`brew outdated`
- 安装后汇总：`scripts/70-post-check.sh`

## 注意
- 部分步骤需要管理员权限（`sudo`）
- 首次安装 Xcode CLT 可能弹窗，需要手动确认
- 某些 npm 包名如果官方变更，脚本会 best-effort 并继续执行

## 下一步（推送 GitHub）
```bash
cd ~/projects/mac-vibe-bootstrap
git init
git add .
git commit -m "feat: bootstrap new mac for vibe coding"
# 创建 public repo 后：
# git remote add origin git@github.com:<YOUR_USER>/mac-vibe-bootstrap.git
# git branch -M main
# git push -u origin main
```
