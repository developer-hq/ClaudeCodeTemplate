#!/bin/bash
# 一键同步 .claude 配置脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Claude Config Sync Tool${NC}"
echo "========================================"

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "${RED}用法: $0 <目标项目路径>${NC}"
    echo "示例: $0 /path/to/your/project"
    exit 1
fi

TARGET_DIR="$1"
REPO_URL="git@github.com:developer-hq/ClaudeCodeTemplate.git"
TEMP_DIR="/tmp/claude-config-sync-$$"

echo -e "${YELLOW}目标目录: $TARGET_DIR${NC}"

# 检查目标目录是否存在
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}错误: 目标目录不存在: $TARGET_DIR${NC}"
    exit 1
fi

# 备份现有的 .claude 配置
if [ -d "$TARGET_DIR/.claude" ]; then
    echo -e "${YELLOW}备份现有 .claude 配置...${NC}"
    cp -r "$TARGET_DIR/.claude" "$TARGET_DIR/.claude.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ 已备份到 .claude.backup.$(date +%Y%m%d_%H%M%S)${NC}"
fi

echo -e "${YELLOW}克隆仓库到临时目录...${NC}"
git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$TEMP_DIR"

cd "$TEMP_DIR"
echo -e "${YELLOW}设置 sparse-checkout...${NC}"
git sparse-checkout set .claude

# 检查是否成功获取到 .claude 文件夹
if [ ! -d "$TEMP_DIR/.claude" ]; then
    echo -e "${RED}错误: 无法从仓库获取 .claude 文件夹${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo -e "${YELLOW}同步 .claude 配置到目标目录...${NC}"
cp -r "$TEMP_DIR/.claude" "$TARGET_DIR/"

# 清理临时目录
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✓ Claude 配置同步完成!${NC}"
echo -e "${YELLOW}位置: $TARGET_DIR/.claude${NC}"

# 显示同步的文件
echo -e "\n${YELLOW}已同步的文件:${NC}"
find "$TARGET_DIR/.claude" -type f | sed 's|^|  - |'

echo -e "\n${GREEN}完成! 现在可以在目标项目中使用 Claude Code 了${NC}"