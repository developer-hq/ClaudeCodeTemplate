#!/bin/bash

# Claude Code Template 快速安装脚本
# 简化版，适合快速部署

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Claude Code Template 快速安装${NC}"
echo "=================================================="

# 基础设置
echo -e "${YELLOW}正在配置基础环境...${NC}"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"

# 复制CLAUDE.md模板
if [ -f "$TEMPLATES_DIR/claude-base-template.md" ]; then
    cp "$TEMPLATES_DIR/claude-base-template.md" CLAUDE.md
    echo "✅ CLAUDE.md模板已创建"
fi

# 创建output-styles目录并复制TDD模式
mkdir -p ~/.claude/output-styles
if [ -f "$TEMPLATES_DIR/tdd-output-style.md" ]; then
    cp "$TEMPLATES_DIR/tdd-output-style.md" ~/.claude/output-styles/tdd.md
    echo "✅ TDD输出样式已安装"
fi

# 检查是否可以运行完整安装脚本
if [ -f "$SCRIPT_DIR/setup-claude-workflow-enhanced.sh" ]; then
    echo -e "\n${BLUE}发现完整安装脚本，是否运行完整配置? (y/N):${NC} "
    read -r run_full
    
    if [ "$run_full" = "y" ] || [ "$run_full" = "Y" ]; then
        bash "$SCRIPT_DIR/setup-claude-workflow-enhanced.sh"
        exit 0
    fi
fi

# 基础Git设置
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "初始化Git仓库..."
    git init
fi

echo -e "\n${GREEN}快速安装完成！${NC}"
echo ""
echo "📖 查看 CLAUDE.md 了解详细使用方法"
echo "🔧 使用 /output-style tdd 切换到测试驱动开发模式"
echo ""
echo "如需完整功能，请运行: bash scripts/setup-claude-workflow-enhanced.sh"