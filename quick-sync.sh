#!/bin/bash
# 一行命令快速同步 Claude 配置

# 用法: ./quick-sync.sh /path/to/target/project
# 或者: bash <(curl -s https://raw.githubusercontent.com/developer-hq/ClaudeCodeTemplate/master/quick-sync.sh) /target/path

TARGET=${1:-.}
TEMP="/tmp/claude-sync-$$"

echo "🔄 同步 Claude 配置到: $TARGET"

# 创建临时目录并克隆
git clone --depth 1 --filter=blob:none --sparse https://github.com/developer-hq/ClaudeCodeTemplate.git "$TEMP" 2>/dev/null
cd "$TEMP" && git sparse-checkout set .claude

# 备份并复制
[ -d "$TARGET/.claude" ] && cp -r "$TARGET/.claude" "$TARGET/.claude.backup.$(date +%s)" && echo "✓ 已备份原配置"
cp -r .claude "$TARGET/" && echo "✓ 配置同步完成"

# 清理
rm -rf "$TEMP"

echo ""
echo "🔑 请配置你的 Bark Token (用于推送通知)"
read -p "请输入你的 Bark Token (留空跳过): " BARK_TOKEN

if [ -n "$BARK_TOKEN" ]; then
    # 替换 settings.json 中的占位符
    SETTINGS_FILE="$TARGET/.claude/settings.json"
    if [ -f "$SETTINGS_FILE" ]; then
        # macOS 和 Linux 兼容的 sed 替换
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/YOUR_BARK_TOKEN_HERE/$BARK_TOKEN/g" "$SETTINGS_FILE"
        else
            sed -i "s/YOUR_BARK_TOKEN_HERE/$BARK_TOKEN/g" "$SETTINGS_FILE"
        fi
        echo "✓ Bark Token 配置完成"
    fi
else
    echo "⚠️  已跳过 Bark Token 配置，推送通知功能将不可用"
    echo "   如需启用，请手动编辑 $TARGET/.claude/settings.json"
    echo "   将 YOUR_BARK_TOKEN_HERE 替换为你的 Bark Token"
fi

echo ""
echo "🎉 Claude 配置已更新到 $TARGET/.claude"