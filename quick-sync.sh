#!/bin/bash
# 一行命令快速同步 Claude 配置

# 用法: ./quick-sync.sh /path/to/target/project
# 或者: bash <(curl -s https://raw.githubusercontent.com/developer-hq/ClaudeCodeTemplate/main/quick-sync.sh) /target/path

TARGET=${1:-.}
TEMP="/tmp/claude-sync-$$"

echo "🔄 同步 Claude 配置到: $TARGET"

# 创建临时目录并克隆
git clone --depth 1 --filter=blob:none --sparse git@github.com:developer-hq/ClaudeCodeTemplate.git "$TEMP" 2>/dev/null
cd "$TEMP" && git sparse-checkout set .claude

# 备份并复制
[ -d "$TARGET/.claude" ] && cp -r "$TARGET/.claude" "$TARGET/.claude.backup.$(date +%s)" && echo "✓ 已备份原配置"
cp -r .claude "$TARGET/" && echo "✓ 配置同步完成"

# 清理
rm -rf "$TEMP"

echo "🎉 Claude 配置已更新到 $TARGET/.claude"