#!/bin/bash

# Claude Code Template 主启动脚本
# 基于 https://bingowith.me/2025/06/17/how-i-use-claude-code/ 的最佳实践优化

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
CONFIG_DIR="$SCRIPT_DIR/config"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 播放声音提示
play_sound() {
    local sound_type="$1"  # success, error, attention
    
    # macOS
    if command -v afplay >/dev/null 2>&1; then
        case "$sound_type" in
            success)
                afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
                ;;
            error)
                afplay /System/Library/Sounds/Sosumi.aiff 2>/dev/null &
                ;;
            attention)
                afplay /System/Library/Sounds/Ping.aiff 2>/dev/null &
                ;;
        esac
    # Linux
    elif command -v paplay >/dev/null 2>&1; then
        case "$sound_type" in
            success)
                paplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null &
                ;;
            error)
                paplay /usr/share/sounds/alsa/Side_Left.wav 2>/dev/null &
                ;;
            attention)
                paplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null &
                ;;
        esac
    # Windows (WSL)
    elif command -v powershell.exe >/dev/null 2>&1; then
        case "$sound_type" in
            success)
                powershell.exe -c "[console]::beep(800,200)" 2>/dev/null &
                ;;
            error)
                powershell.exe -c "[console]::beep(400,500)" 2>/dev/null &
                ;;
            attention)
                powershell.exe -c "[console]::beep(600,300)" 2>/dev/null &
                ;;
        esac
    # 通用终端提示音
    else
        printf '\a'  # ASCII Bell
    fi
}

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                 🚀 Claude Code Template                        ║
║                                                              ║
║  🎯 Linus风格 | 🐍 uv集成 | 🔧 MCP | 🤖 Qwen | 🌳 Worktree   ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 显示菜单
show_menu() {
    echo -e "${YELLOW}选择操作:${NC}"
    echo "  1) 🏗️  完整安装 (推荐新项目)"
    echo "  2) ⚡ 快速安装 (基础功能)"
    echo "  3) 🤖 Qwen集成 (AI代理协作)"
    echo "  4) 🌳 Git Worktree管理"
    echo "  5) 🔧 配置VSCode集成"
    echo "  6) 📋 查看状态"
    echo "  7) ❓ 帮助文档"
    echo "  0) 🚪 退出"
    echo ""
    echo -n "请输入选择 [0-7]: "
}

# Git Worktree 管理
manage_worktrees() {
    log_step "Git Worktree 管理"
    
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "当前目录不是Git仓库"
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Worktree 操作:${NC}"
    echo "  1) 📋 列出所有worktree"
    echo "  2) ➕ 创建新功能分支worktree"
    echo "  3) 🗑️  删除worktree"
    echo "  4) 🔄 切换到worktree"
    echo "  0) ↩️  返回主菜单"
    echo ""
    read -p "选择操作 [0-4]: " wt_choice
    
    case $wt_choice in
        1)
            echo -e "${BLUE}当前所有 worktree:${NC}"
            git worktree list
            ;;
        2)
            read -p "输入新功能分支名 (例: feature/user-auth): " branch_name
            if [ -n "$branch_name" ]; then
                local wt_dir="../$(basename "$PWD")-$branch_name"
                git worktree add -b "$branch_name" "$wt_dir"
                log_success "Worktree 创建完成: $wt_dir"
                echo "进入新worktree: cd $wt_dir"
                play_sound "success"
            fi
            ;;
        3)
            git worktree list
            read -p "输入要删除的worktree路径: " wt_path
            if [ -n "$wt_path" ] && [ -d "$wt_path" ]; then
                git worktree remove "$wt_path"
                log_success "Worktree 已删除: $wt_path"
            fi
            ;;
        4)
            git worktree list
            read -p "输入worktree路径: " wt_path
            if [ -n "$wt_path" ] && [ -d "$wt_path" ]; then
                echo "切换命令: cd $wt_path"
                log_info "请手动执行上述命令切换到worktree"
            fi
            ;;
        0)
            return 0
            ;;
        *)
            log_error "无效选择"
            ;;
    esac
}

# VSCode 集成配置
setup_vscode_integration() {
    log_step "配置VSCode集成"
    
    local vscode_dir=".vscode"
    mkdir -p "$vscode_dir"
    
    # 创建tasks.json
    cat > "$vscode_dir/tasks.json" << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Claude Code: Quick Setup",
            "type": "shell",
            "command": "bash",
            "args": ["${workspaceFolder}/scripts/quick-setup.sh"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": []
        },
        {
            "label": "Claude Code: Full Setup",
            "type": "shell", 
            "command": "bash",
            "args": ["${workspaceFolder}/scripts/setup-claude-workflow-enhanced.sh"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": []
        },
        {
            "label": "Git Worktree: New Feature",
            "type": "shell",
            "command": "bash",
            "args": ["-c", "read -p 'Feature branch name: ' name && git worktree add -b $name ../${workspaceFolderBasename}-$name"],
            "group": "build"
        }
    ]
}
EOF

    # 创建settings.json
    cat > "$vscode_dir/settings.json" << 'EOF'
{
    "files.watcherExclude": {
        "**/.claude/**": true,
        "**/node_modules/**": true,
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/*/**": true
    },
    "search.exclude": {
        "**/.claude/todos": true,
        "**/.claude/shell-snapshots": true
    },
    "claude-code.autoCommit": true,
    "claude-code.soundNotifications": true,
    "terminal.integrated.shellIntegration.enabled": true
}
EOF

    # 创建hooks配置文件
    mkdir -p .claude
    cat > .claude/vscode-hooks.json << 'EOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": {"type": "always"},
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/sound-notification.sh success",
            "description": "Task completion sound"
          }
        ]
      }
    ],
    "Error": [
      {
        "matcher": {"type": "always"},
        "hooks": [
          {
            "type": "command", 
            "command": "bash scripts/sound-notification.sh error",
            "description": "Error sound notification"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": {
          "type": "regex",
          "pattern": "人类介入|human.*intervention|需要.*确认"
        },
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/sound-notification.sh attention",
            "description": "Human intervention needed"
          }
        ]
      }
    ]
  }
}
EOF

    log_success "VSCode集成配置完成"
    log_info "已创建:"
    echo "  - .vscode/tasks.json (快捷任务)"
    echo "  - .vscode/settings.json (项目设置)"
    echo "  - .claude/vscode-hooks.json (声音提示)"
    play_sound "success"
}

# 查看状态
show_status() {
    log_step "系统状态检查"
    
    echo -e "${CYAN}📋 环境检查:${NC}"
    
    # Git检查
    if command -v git >/dev/null 2>&1; then
        if git rev-parse --git-dir >/dev/null 2>&1; then
            echo "  ✅ Git仓库: $(git rev-parse --show-toplevel)"
            echo "  📍 当前分支: $(git branch --show-current)"
            echo "  🌳 Worktrees: $(git worktree list | wc -l) 个"
        else
            echo "  ❌ 当前目录不是Git仓库"
        fi
    else
        echo "  ❌ Git未安装"
    fi
    
    # Claude Code检查
    if command -v claude >/dev/null 2>&1; then
        echo "  ✅ Claude Code CLI"
    else
        echo "  ❌ Claude Code CLI未安装"
    fi
    
    # uv检查
    if command -v uv >/dev/null 2>&1; then
        echo "  ✅ uv: $(uv --version)"
    else
        echo "  ❌ uv未安装"
    fi
    
    # Python检查
    if command -v python3 >/dev/null 2>&1; then
        echo "  ✅ Python: $(python3 --version)"
    else
        echo "  ❌ Python未安装"
    fi
    
    echo ""
    echo -e "${CYAN}📁 文件状态:${NC}"
    echo "  📂 Templates: $(ls -1 templates/ 2>/dev/null | wc -l) 个文件"
    echo "  🔧 Scripts: $(ls -1 scripts/ 2>/dev/null | wc -l) 个文件"  
    echo "  ⚙️ Config: $(ls -1 config/ 2>/dev/null | wc -l) 个文件"
    
    if [ -f ".claude/settings.json" ]; then
        echo "  ✅ Claude设置已配置"
    else
        echo "  ❌ Claude设置未配置"
    fi
}

# 主循环
main() {
    show_banner
    
    while true; do
        echo ""
        show_menu
        read -r choice
        
        case $choice in
            1)
                log_info "启动完整安装..."
                play_sound "attention"
                bash "$SCRIPTS_DIR/setup-claude-workflow-enhanced.sh"
                if [ $? -eq 0 ]; then
                    play_sound "success"
                else
                    play_sound "error"
                fi
                ;;
            2)
                log_info "启动快速安装..."
                bash "$SCRIPTS_DIR/quick-setup.sh"
                if [ $? -eq 0 ]; then
                    play_sound "success"
                else
                    play_sound "error"
                fi
                ;;
            3)
                log_info "安装Qwen集成..."
                bash "$SCRIPTS_DIR/setup-qwen-integration.sh"
                if [ $? -eq 0 ]; then
                    play_sound "success"
                else
                    play_sound "error"
                fi
                ;;
            4)
                manage_worktrees
                ;;
            5)
                setup_vscode_integration
                ;;
            6)
                show_status
                ;;
            7)
                log_info "打开README文档..."
                if command -v code >/dev/null 2>&1; then
                    code README.md
                elif [ -f README.md ]; then
                    cat README.md
                else
                    echo "README.md 未找到"
                fi
                ;;
            0)
                log_info "退出Claude Code Template"
                play_sound "success"
                exit 0
                ;;
            *)
                log_error "无效选择，请输入0-7"
                play_sound "error"
                ;;
        esac
    done
}

# 检查脚本完整性
if [ ! -d "$SCRIPTS_DIR" ]; then
    log_error "scripts目录不存在，请检查安装"
    exit 1
fi

# 创建声音通知脚本
mkdir -p scripts
cat > scripts/sound-notification.sh << 'EOF'
#!/bin/bash
# 声音通知脚本
sound_type="${1:-success}"

# macOS
if command -v afplay >/dev/null 2>&1; then
    case "$sound_type" in
        success) afplay /System/Library/Sounds/Glass.aiff 2>/dev/null & ;;
        error) afplay /System/Library/Sounds/Sosumi.aiff 2>/dev/null & ;;
        attention) afplay /System/Library/Sounds/Ping.aiff 2>/dev/null & ;;
    esac
# Linux  
elif command -v paplay >/dev/null 2>&1; then
    case "$sound_type" in
        success) paplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null & ;;
        error) paplay /usr/share/sounds/alsa/Side_Left.wav 2>/dev/null & ;;  
        attention) paplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null & ;;
    esac
# Windows WSL
elif command -v powershell.exe >/dev/null 2>&1; then
    case "$sound_type" in
        success) powershell.exe -c "[console]::beep(800,200)" 2>/dev/null & ;;
        error) powershell.exe -c "[console]::beep(400,500)" 2>/dev/null & ;;
        attention) powershell.exe -c "[console]::beep(600,300)" 2>/dev/null & ;;
    esac
else
    printf '\a'  # ASCII Bell
fi
EOF

# 启动主程序
main "$@"