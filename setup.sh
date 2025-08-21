#!/bin/bash

# Claude Code Template Setup - 简化版
# 仅做必要的初始化：Git + UV

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════╗"
echo "║        🚀 Claude Code Template             ║"
echo "║                                            ║" 
echo "║      快速项目初始化 Git + UV               ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

# 检查是否在 git 仓库中
if [ ! -d ".git" ]; then
    echo_status "初始化 Git 仓库..."
    git init
    echo_success "Git 仓库初始化完成"
else
    echo_success "Git 仓库已存在"
fi

# 检查 UV 是否安装
if ! command -v uv &> /dev/null; then
    echo_warning "UV 未安装，正在安装..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source ~/.bashrc || source ~/.zshrc || true
    echo_success "UV 安装完成"
else
    echo_success "UV 已安装: $(uv --version)"
fi

# 可选：初始化 Python 项目
echo ""
read -p "是否初始化 Python 项目? (y/N): " init_python
if [[ $init_python =~ ^[Yy]$ ]]; then
    echo_status "初始化 Python 项目..."
    uv init --no-readme
    
    # 添加常用开发依赖
    echo_status "添加开发依赖..."
    uv add --dev ruff pytest mypy pre-commit
    
    # 配置 pre-commit
    echo_status "配置 pre-commit..."
    cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.6
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.7.1
    hooks:
      - id: mypy
        additional_dependencies: [types-requests]
EOF
    
    # 安装 pre-commit hooks
    uv run pre-commit install
    
    echo_success "Python 项目初始化完成"
fi

echo ""
echo_success "🎉 Claude Code Template 设置完成！"
echo ""
echo_status "📋 项目结构："
echo "├── .claude/                   # Claude 项目配置目录"
echo "│   ├── agents/               # Git agent 等专业代理"
echo "│   ├── commands/             # 项目命令库"
echo "│   └── output-styles/        # 输出样式"
echo "├── .gitignore                 # Git 忽略文件"
echo "├── CLAUDE.md                  # Claude 项目指令"
echo "└── setup.sh                   # 本脚本"
echo ""
echo_status "🚀 后续操作："
echo "  claude                       # 启动 Claude Code"
echo "  /git-setup-remote            # 配置 GitHub 推送"
echo "  /git-push-safe               # 安全推送代码"
echo "  /output-style qwen           # 启用 Qwen AI 协作模式"
echo "  uv add <package>             # 添加 Python 包"