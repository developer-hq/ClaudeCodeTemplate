#!/bin/bash

# Qwen Code Integration Setup Script
# 基于 Linus 哲学：实用、简洁、向后兼容

set -e

echo "🤖 开始配置 Qwen Code 集成..."

# 检查是否在 git 仓库中
if [ ! -d ".git" ]; then
    echo "❌ 错误：请在 git 仓库根目录运行此脚本"
    exit 1
fi

# 创建 .claude 目录（如果不存在）
mkdir -p .claude

# 检查 Python 环境
echo "🐍 检查 Python 环境..."
if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ 错误：需要 Python 3.6+ 环境"
    exit 1
fi

# 安装必要的 Python 依赖
echo "📦 安装 Python 依赖..."
python3 -m pip install --quiet requests

# 检查 Qwen Code CLI 是否可用
echo "🔍 检查 Qwen Code CLI..."
if command -v qwen-code >/dev/null 2>&1; then
    QWEN_CLI_VERSION=$(qwen-code --version 2>/dev/null || echo "unknown")
    echo "✅ Qwen Code CLI 已安装: $QWEN_CLI_VERSION"
    ENABLE_QWEN="true"
else
    echo "⚠️  Qwen Code CLI 未安装"
    echo "   如需安装，请访问: https://github.com/QwenLM/Qwen"
    echo "   系统将仅使用 Claude（完全兼容现有功能）"
    ENABLE_QWEN="false"
fi

# 复制配置文件到 .claude 目录
echo "⚙️  配置 Qwen 集成..."
cp qwen-config.json .claude/qwen-config.json

# 设置环境变量
echo "🔧 配置环境变量..."
cat > .claude/qwen-env.sh << EOF
#!/bin/bash
# Qwen Code Integration Environment

# 启用/禁用 Qwen 集成
export ENABLE_QWEN_INTEGRATION=$ENABLE_QWEN

# Python 路径（用于运行 qwen_subagent.py）
export QWEN_SUBAGENT_PATH="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)/qwen_subagent.py"

# 日志配置
export QWEN_LOG_LEVEL=INFO
export QWEN_LOG_FILE=.claude/qwen.log

# API 配置（可选，如果使用 Qwen API）
# export QWEN_API_KEY="your-api-key-here"
# export QWEN_API_ENDPOINT="https://api.qwen.com/v1"

echo "Qwen integration: \$ENABLE_QWEN_INTEGRATION"
EOF

chmod +x .claude/qwen-env.sh

# 创建便利脚本
echo "🛠️  创建便利脚本..."

# Qwen 调用脚本
cat > .claude/qwen-call.sh << 'EOF'
#!/bin/bash
# Qwen Code 调用包装脚本

# 加载环境变量
source "$(dirname "$0")/qwen-env.sh"

# 检查是否启用了 Qwen 集成
if [ "$ENABLE_QWEN_INTEGRATION" != "true" ]; then
    echo "Qwen integration is disabled. Using Claude fallback."
    exit 1
fi

# 调用 Python 子代理
python3 "$QWEN_SUBAGENT_PATH" "$@"
EOF

chmod +x .claude/qwen-call.sh

# 状态检查脚本
cat > .claude/qwen-status.sh << 'EOF'
#!/bin/bash
# Qwen 状态检查脚本

# 加载环境变量
source "$(dirname "$0")/qwen-env.sh"

echo "=== Qwen Code Integration Status ==="
echo "Integration enabled: $ENABLE_QWEN_INTEGRATION"

if [ "$ENABLE_QWEN_INTEGRATION" = "true" ]; then
    echo "CLI available: $(command -v qwen-code >/dev/null && echo "Yes" || echo "No")"
    
    if command -v qwen-code >/dev/null; then
        echo "CLI version: $(qwen-code --version 2>/dev/null || echo "unknown")"
    fi
    
    echo "API endpoint: ${QWEN_API_ENDPOINT:-"Not configured"}"
    echo "API key: ${QWEN_API_KEY:+"Configured"}"
    echo "Log file: $QWEN_LOG_FILE"
fi

# 显示最近的日志（如果存在）
if [ -f "$QWEN_LOG_FILE" ]; then
    echo ""
    echo "=== Recent Activity ==="
    tail -n 5 "$QWEN_LOG_FILE"
fi
EOF

chmod +x .claude/qwen-status.sh

# 测试脚本
cat > .claude/qwen-test.sh << 'EOF'
#!/bin/bash
# Qwen 集成测试脚本

echo "🧪 测试 Qwen Code 集成..."

# 加载环境变量
source "$(dirname "$0")/qwen-env.sh"

# 基础测试
echo "1. 环境变量测试..."
echo "   ENABLE_QWEN_INTEGRATION: $ENABLE_QWEN_INTEGRATION"
echo "   QWEN_SUBAGENT_PATH: $QWEN_SUBAGENT_PATH"

# Python 模块测试
echo "2. Python 模块测试..."
if python3 -c "import sys; sys.path.append('.'); import qwen_subagent; print('✅ qwen_subagent 模块加载成功')" 2>/dev/null; then
    echo "   ✅ Python 模块正常"
else
    echo "   ❌ Python 模块错误"
    exit 1
fi

# 功能测试
echo "3. 功能测试..."
TEST_RESULT=$(python3 "$QWEN_SUBAGENT_PATH" "测试任务：Hello World" 2>&1)
if [ $? -eq 0 ]; then
    echo "   ✅ 基础功能正常"
    echo "   输出: $(echo "$TEST_RESULT" | head -n 1)"
else
    echo "   ❌ 基础功能错误"
    echo "   错误: $TEST_RESULT"
    exit 1
fi

echo "✅ 所有测试通过！"
EOF

chmod +x .claude/qwen-test.sh

# 更新现有的 setup script
echo "🔄 更新现有脚本..."

# 检查是否存在现有的 setup 脚本，并添加 Qwen 集成
if [ -f "setup-claude-workflow-enhanced.sh" ]; then
    echo "   将 Qwen 集成添加到现有工作流..."
    
    # 备份原文件
    cp setup-claude-workflow-enhanced.sh setup-claude-workflow-enhanced.sh.backup
    
    # 在文件末尾添加 Qwen 集成调用
    cat >> setup-claude-workflow-enhanced.sh << 'EOF'

# Qwen Code 集成（如果存在）
if [ -f "setup-qwen-integration.sh" ]; then
    echo "🤖 配置 Qwen Code 集成..."
    source setup-qwen-integration.sh
fi
EOF
fi

# 运行测试
echo "🧪 运行集成测试..."
if .claude/qwen-test.sh; then
    echo "✅ Qwen Code 集成配置完成！"
else
    echo "❌ 集成测试失败，请检查配置"
    exit 1
fi

# 显示使用说明
echo ""
echo "📖 使用说明："
echo ""
echo "1. 检查状态:"
echo "   .claude/qwen-status.sh"
echo ""
echo "2. 直接调用 Qwen:"
echo "   .claude/qwen-call.sh \"您的任务描述\""
echo ""
echo "3. 在 Python 中使用:"
echo "   from qwen_subagent import process_user_request"
echo "   result = process_user_request(\"任务描述\")"
echo ""
echo "4. 查看日志:"
echo "   tail -f .claude/qwen.log"
echo ""
echo "🎯 集成特性："
echo "   ✅ 智能任务路由（基于内容和规模）"
echo "   ✅ 自动回退到 Claude（零破坏性）"
echo "   ✅ 支持 CLI 和 API 两种调用方式"
echo "   ✅ 完整的错误处理和监控"
echo ""
echo "🚀 现在您可以享受 Qwen + Claude 的智能协作了！"