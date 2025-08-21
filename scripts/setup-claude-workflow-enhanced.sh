#!/bin/bash

# Claude Code 增强版工作流一键安装脚本
# 创建者: Claude (Linus风格设计)
# 支持: Git初始化、uv项目管理、MCP配置、pre-commit集成

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 配置变量
USE_UV=false
PYTHON_VERSION=""
USE_PRECOMMIT=false
PROJECT_NAME=""

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

# 显示帮助信息
show_help() {
    echo "Claude Code 增强版工作流安装器"
    echo ""
    echo "功能特性:"
    echo "  🎯 Linus风格代码规范和工作流"
    echo "  🚀 智能Git自动提交 (token优化)"
    echo "  🐍 uv Python项目管理支持"
    echo "  🔧 MCP服务自动配置"
    echo "  ✨ pre-commit集成"
    echo "  📋 TDD模式 (output-style切换)"
    echo ""
    echo "使用方式:"
    echo "  $0                    # 交互式安装"
    echo "  $0 --help           # 显示此帮助"
    echo ""
    echo "支持的工作流:"
    echo "  - 传统Git项目"
    echo "  - uv Python项目 (推荐)"
    echo "  - pre-commit代码质量检查"
}

# 交互式配置收集
collect_configuration() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                   Claude Code 工作流配置                        ║
║                                                              ║
║  🎯 智能自动提交 | 🐍 uv集成 | 🔧 MCP配置 | ✨ pre-commit    ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # 项目名称
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(basename "$(pwd)")
        echo -e "项目名称 [${GREEN}$PROJECT_NAME${NC}]: "
        read -r input_name
        if [ -n "$input_name" ]; then
            PROJECT_NAME="$input_name"
        fi
    fi
    
    # uv选择
    echo -e "\n${YELLOW}🐍 是否使用 uv 创建 Python 项目? (推荐) (y/N):${NC} "
    read -r use_uv_input
    if [ "$use_uv_input" = "y" ] || [ "$use_uv_input" = "Y" ]; then
        USE_UV=true
        
        # Python版本选择
        echo -e "Python版本 [${GREEN}3.11${NC}]: "
        read -r py_version
        if [ -n "$py_version" ]; then
            PYTHON_VERSION="$py_version"
        else
            PYTHON_VERSION="3.11"
        fi
        
        # pre-commit选择
        echo -e "\n${YELLOW}✨ 是否启用 pre-commit? (y/N):${NC} "
        read -r precommit_input
        if [ "$precommit_input" = "y" ] || [ "$precommit_input" = "Y" ]; then
            USE_PRECOMMIT=true
        fi
    fi
    
    # 配置确认
    echo -e "\n${GREEN}═══ 配置确认 ═══${NC}"
    echo "项目名称: $PROJECT_NAME"
    echo "使用 uv: $USE_UV"
    [ "$USE_UV" = true ] && echo "Python版本: $PYTHON_VERSION"
    [ "$USE_UV" = true ] && echo "pre-commit: $USE_PRECOMMIT"
    echo ""
    echo "是否继续安装? (Y/n): "
    read -r confirm
    if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
        log_info "安装已取消"
        exit 0
    fi
}

# 依赖安装指导
show_install_guide() {
    local missing_deps="$1"
    
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ 缺少必要依赖，请先安装以下工具：${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if echo "$missing_deps" | grep -q "git"; then
        echo -e "${YELLOW}📦 Git 版本控制工具${NC}"
        echo "   Ubuntu/Debian: sudo apt update && sudo apt install git"
        echo "   CentOS/RHEL:   sudo yum install git"
        echo "   macOS:         brew install git"
        echo "   Windows:       https://git-scm.com/download/win"
        echo ""
    fi
    
    if echo "$missing_deps" | grep -q "node"; then
        echo -e "${YELLOW}📦 Node.js JavaScript运行时${NC}"
        echo "   推荐使用 nvm 安装："
        echo "   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "   source ~/.bashrc && nvm install node"
        echo "   或直接下载: https://nodejs.org/"
        echo ""
    fi
    
    if echo "$missing_deps" | grep -q "claude"; then
        echo -e "${YELLOW}📦 Claude Code CLI工具${NC}"
        echo "   官方安装文档: https://docs.anthropic.com/en/docs/claude-code/quickstart"
        echo "   通常通过以下方式安装:"
        echo "   - 从官方网站下载安装包"
        echo "   - 或使用包管理器安装"
        echo ""
    fi
    
    if echo "$missing_deps" | grep -q "uv"; then
        echo -e "${YELLOW}📦 uv Python项目管理工具${NC}"
        echo "   自动安装: curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo "   手动安装: https://docs.astral.sh/uv/getting-started/installation/"
        echo ""
    fi
    
    if echo "$missing_deps" | grep -q "python"; then
        echo -e "${YELLOW}📦 Python 编程语言${NC}"
        echo "   Ubuntu/Debian: sudo apt install python3 python3-pip"
        echo "   CentOS/RHEL:   sudo yum install python3 python3-pip"
        echo "   macOS:         brew install python"
        echo "   Windows:       https://www.python.org/downloads/"
        echo ""
    fi
    
    echo -e "${BLUE}💡 安装完成后，请重新运行此脚本${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 检查依赖
check_dependencies() {
    log_step "检查系统依赖..."
    
    local missing_deps=""
    local has_missing=false
    
    # 检查基础工具
    if ! command -v git >/dev/null 2>&1; then
        missing_deps="$missing_deps git"
        has_missing=true
        log_error "Git未找到"
    fi
    
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        log_error "curl或wget未找到，无法下载依赖"
        missing_deps="$missing_deps curl"
        has_missing=true
    fi
    
    # 检查Claude Code
    if ! command -v claude >/dev/null 2>&1; then
        log_warning "Claude Code CLI未找到"
        missing_deps="$missing_deps claude"
        has_missing=true
    fi
    
    # 检查Node.js（用于某些MCP服务）
    if ! command -v node >/dev/null 2>&1; then
        log_warning "Node.js未找到，某些MCP服务可能无法使用"
        # Node.js不是必需的，只是警告
    fi
    
    # 检查Python（如果使用uv）
    if [ "$USE_UV" = true ]; then
        if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
            log_error "Python未找到，uv项目需要Python环境"
            missing_deps="$missing_deps python"
            has_missing=true
        fi
        
        # 检查uv
        if ! command -v uv >/dev/null 2>&1; then
            log_info "uv未找到，正在尝试自动安装..."
            
            # 尝试自动安装uv
            if command -v curl >/dev/null 2>&1; then
                if curl -LsSf https://astral.sh/uv/install.sh | sh; then
                    export PATH="$HOME/.local/bin:$PATH"
                    if command -v uv >/dev/null 2>&1; then
                        log_success "uv自动安装成功"
                    else
                        log_warning "uv自动安装失败，请手动安装"
                        missing_deps="$missing_deps uv"
                        has_missing=true
                    fi
                else
                    log_warning "uv自动安装失败"
                    missing_deps="$missing_deps uv"
                    has_missing=true
                fi
            else
                missing_deps="$missing_deps uv"
                has_missing=true
            fi
        fi
    fi
    
    # 如果有缺少的依赖，显示安装指导并退出
    if [ "$has_missing" = true ]; then
        show_install_guide "$missing_deps"
        echo ""
        echo -e "${YELLOW}是否忽略缺少的依赖继续安装? (可能导致部分功能不可用) (y/N):${NC} "
        read -r ignore_missing
        
        if [ "$ignore_missing" != "y" ] && [ "$ignore_missing" != "Y" ]; then
            log_info "安装已取消，请先安装必要依赖"
            exit 1
        else
            log_warning "忽略缺少的依赖，继续安装（部分功能可能不可用）"
        fi
    fi
    
    log_success "依赖检查完成"
}

# 项目初始化
initialize_project() {
    log_step "初始化项目..."
    
    if [ "$USE_UV" = true ]; then
        # uv项目初始化
        if [ ! -f "pyproject.toml" ]; then
            log_info "创建uv Python项目..."
            uv init --name "$PROJECT_NAME" --python "$PYTHON_VERSION"
            log_success "uv项目创建完成"
        else
            log_info "检测到现有pyproject.toml，同步环境..."
            uv sync
        fi
        
        # 添加常用开发依赖
        log_info "添加开发依赖..."
        uv add --dev pytest black isort mypy
        
    else
        # 传统Git项目
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            log_info "初始化Git仓库..."
            git init
            
            # 创建基础.gitignore
            if [ ! -f ".gitignore" ]; then
                create_gitignore
            fi
        fi
    fi
}

# 创建gitignore
create_gitignore() {
    log_info "创建.gitignore..."
    
    cat > .gitignore << 'EOF'
# Claude Code工作流
.claude/git-hook.log
.claude/shell-snapshots/
.claude/todos/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/
.python-version

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Testing
.pytest_cache/
.coverage
.coverage.*
.cache
htmlcov/
.tox/
.nox/

# Jupyter
.ipynb_checkpoints

# macOS
.DS_Store

# Windows
Thumbs.db
ehthumbs.db
Desktop.ini
EOF

    log_success ".gitignore创建完成"
}

# 配置pre-commit
setup_precommit() {
    if [ "$USE_PRECOMMIT" = true ]; then
        log_step "配置pre-commit..."
        
        # 安装pre-commit
        uv add --dev pre-commit
        
        # 创建pre-commit配置
        cat > .pre-commit-config.yaml << 'EOF'
repos:
  # uv集成
  - repo: https://github.com/astral-sh/uv-pre-commit
    rev: 0.8.12
    hooks:
      - id: uv-lock
      - id: uv-export

  # Python代码质量
  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
        args: ["--profile", "black"]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
        additional_dependencies: [types-requests]

  # 通用检查
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
EOF

        # 安装git hooks
        uv run pre-commit install
        log_success "pre-commit配置完成"
    fi
}

# 创建Claude目录结构
setup_claude_dirs() {
    log_step "创建Claude配置目录..."
    
    mkdir -p .claude
    mkdir -p ~/.claude/output-styles
    
    log_success "目录结构创建完成"
}

# 创建智能提交hook
create_smart_commit_hook() {
    log_step "创建智能提交hook..."
    
    cat > .claude/smart-commit-hook.sh << 'EOF'
#!/bin/bash

# Claude Code 智能提交 Hook (优化版)
# 只在对话结束后触发，节省token

set -e

LOG_FILE="$HOME/.claude/git-hook.log"
LOCK_FILE="/tmp/claude-hook.lock"

# 日志函数
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SMART-COMMIT] $1" >> "$LOG_FILE"
}

# 检查是否需要执行
should_run() {
    if [ -f "$LOCK_FILE" ]; then
        log_action "检测到锁文件，跳过执行"
        exit 0
    fi
    
    touch "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"' EXIT
    
    if git diff-index --quiet HEAD --; then
        log_action "没有需要提交的更改"
        exit 0
    fi
    
    return 0
}

# 安全检查
safety_check() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_action "错误: 不在git仓库中"
        exit 1
    fi
    
    # 检查冲突
    CONFLICT_FILES=$(git status --porcelain | grep "^UU" | wc -l)
    if [ $CONFLICT_FILES -gt 0 ]; then
        log_action "错误: 检测到合并冲突，需要人类介入"
        echo "❌ 检测到合并冲突，请手动解决"
        exit 1
    fi
    
    # 检查远程状态
    CURRENT_BRANCH=$(git branch --show-current)
    git fetch origin $CURRENT_BRANCH 2>/dev/null || true
    
    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/$CURRENT_BRANCH 2>/dev/null || echo "no-remote")
    
    if [ "$REMOTE_COMMIT" != "no-remote" ] && [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        BEHIND_COUNT=$(git rev-list --count HEAD..origin/$CURRENT_BRANCH 2>/dev/null || echo "0")
        if [ "$BEHIND_COUNT" != "0" ]; then
            log_action "警告: 本地分支落后于远程 $BEHIND_COUNT 个提交"
            echo "⚠️  本地分支落后，建议先 git pull"
        fi
    fi
}

# 生成智能提交消息
generate_commit_message() {
    NEW_FILES=$(git diff --cached --name-only --diff-filter=A | wc -l)
    MODIFIED_FILES=$(git diff --cached --name-only --diff-filter=M | wc -l)
    DELETED_FILES=$(git diff --cached --name-only --diff-filter=D | wc -l)
    
    # 智能判断提交类型
    COMMIT_TYPE="dev"
    if [ $NEW_FILES -gt 0 ] && [ $MODIFIED_FILES -eq 0 ] && [ $DELETED_FILES -eq 0 ]; then
        COMMIT_TYPE="feat"
    elif [ $DELETED_FILES -gt 0 ]; then
        COMMIT_TYPE="cleanup"
    elif [ $MODIFIED_FILES -gt $NEW_FILES ]; then
        COMMIT_TYPE="fix"
    fi
    
    # 生成文件变更描述
    FILE_SUMMARY=""
    [ $NEW_FILES -gt 0 ] && FILE_SUMMARY="${FILE_SUMMARY}新增${NEW_FILES}个文件"
    [ $MODIFIED_FILES -gt 0 ] && [ -n "$FILE_SUMMARY" ] && FILE_SUMMARY="${FILE_SUMMARY},"
    [ $MODIFIED_FILES -gt 0 ] && FILE_SUMMARY="${FILE_SUMMARY}修改${MODIFIED_FILES}个文件"
    [ $DELETED_FILES -gt 0 ] && [ -n "$FILE_SUMMARY" ] && FILE_SUMMARY="${FILE_SUMMARY},"
    [ $DELETED_FILES -gt 0 ] && FILE_SUMMARY="${FILE_SUMMARY}删除${DELETED_FILES}个文件"
    
    echo "[$COMMIT_TYPE] $FILE_SUMMARY 自动提交 Claude"
}

# 主执行逻辑
main() {
    log_action "开始执行智能提交hook"
    
    should_run
    safety_check
    
    # 运行pre-commit (如果存在)
    if [ -f ".pre-commit-config.yaml" ] && command -v pre-commit >/dev/null 2>&1; then
        echo "🔧 运行pre-commit检查..."
        if ! pre-commit run --all-files; then
            log_action "pre-commit检查失败，需要人类修复"
            echo "❌ pre-commit检查失败，请修复后重试"
            exit 1
        fi
    fi
    
    git add .
    
    COMMIT_MSG=$(generate_commit_message)
    git commit -m "$COMMIT_MSG"
    
    COMMIT_HASH=$(git rev-parse --short HEAD)
    log_action "成功提交: $COMMIT_HASH - $COMMIT_MSG"
    
    echo "✅ 自动提交完成: $COMMIT_HASH"
    echo "📝 $COMMIT_MSG"
    
    # 后台推送（可选）
    if [ "${AUTO_PUSH:-false}" = "true" ]; then
        CURRENT_BRANCH=$(git branch --show-current)
        git push origin $CURRENT_BRANCH &
        PUSH_PID=$!
        echo "🚀 正在后台推送到 origin/$CURRENT_BRANCH (PID: $PUSH_PID)"
        echo "   停止推送: kill $PUSH_PID"
        log_action "后台推送启动 PID: $PUSH_PID"
    fi
}

main "$@"
EOF

    chmod +x .claude/smart-commit-hook.sh
    log_success "智能提交hook创建完成"
}

# 创建TDD output style
create_tdd_output_style() {
    log_step "创建TDD output style..."
    
    cat > ~/.claude/output-styles/tdd.md << 'EOF'
# TDD (Test-Driven Development) Output Style

## Name
TDD

## Description  
Test-Driven Development mode with strict Red-Green-Refactor cycle enforcement

## Instructions

You are now in **Test-Driven Development mode**. Follow the Red-Green-Refactor cycle strictly.

## Core TDD Philosophy

**Red-Green-Refactor Cycle**:
1. 🔴 **Red**: Write a failing test first
2. 🟢 **Green**: Write minimal code to make the test pass  
3. 🔵 **Refactor**: Improve code while keeping tests green

## TDD Workflow Rules

### Before Writing Any Production Code:
```
🔴 TDD Step 1: RED PHASE
─────────────────────────
[Write the failing test that captures the desired behavior]
```

### After Writing Minimal Production Code:
```
🟢 TDD Step 2: GREEN PHASE  
─────────────────────────
[Run tests and verify they pass with minimal implementation]
```

### After Tests Pass:
```
🔵 TDD Step 3: REFACTOR PHASE
─────────────────────────
[Improve code structure while maintaining passing tests]
```

## Test Execution Commands

Always use these commands to run tests:
- **uv**: `uv run pytest` or `uv run python -m pytest`
- **Node.js**: `npm test` or `npm run test`
- **Python**: `pytest -v` or `python -m pytest`
- **Rust**: `cargo test`
- **Go**: `go test ./...`

## TDD Output Format

Always show test results in this format:
```
📊 Test Results:
✅ Passing: X tests
❌ Failing: Y tests  
⏱️  Duration: Z ms

Next Action: [Red/Green/Refactor]
```

## Code Quality Standards (TDD Mode)

1. **One Function, One Purpose**: Each function should do exactly one thing well
2. **Test Coverage**: Every function must have corresponding tests
3. **Fail Fast**: Tests should fail quickly and with clear error messages
4. **Minimal Implementation**: Write only enough code to make tests pass
5. **Refactor Fearlessly**: Improve code knowing tests will catch regressions

## Exit TDD Mode

Use `/output-style default` to return to normal development mode.

---
*TDD Mode Active - Write Tests First! 🔴→🟢→🔵*
EOF

    log_success "TDD output style创建完成"
}

# 配置MCP服务
setup_mcp_services() {
    log_step "配置MCP服务..."
    
    echo "正在配置必需的MCP服务..."
    
    # Context7 - 文档查询
    echo "🔧 配置 Context7 MCP (文档查询)..."
    claude mcp add --transport http context7 https://mcp.context7.com/mcp || log_warning "Context7 MCP配置可能失败"
    
    # Grep - 代码搜索
    echo "🔧 配置 Grep MCP (GitHub代码搜索)..."
    claude mcp add --transport http grep https://mcp.grep.app || log_warning "Grep MCP配置可能失败"
    
    # Specs workflow - 文档工作流
    echo "🔧 配置 Specs Workflow MCP (需求文档)..."
    claude mcp add spec-workflow-mcp -s user -- npx -y spec-workflow-mcp@latest || log_warning "Specs Workflow MCP配置可能失败"
    
    log_success "MCP服务配置完成"
}

# 更新Claude settings
update_claude_settings() {
    log_step "配置Claude Code settings..."
    
    SETTINGS_FILE="$HOME/.claude/settings.json"
    
    # 备份现有设置
    if [ -f "$SETTINGS_FILE" ]; then
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%s)"
        log_info "已备份现有设置"
    fi
    
    # 创建优化的设置
    cat > "$SETTINGS_FILE" << EOF
{
  "hooks": {
    "Stop": [
      {
        "matcher": {
          "type": "always"
        },
        "hooks": [
          {
            "type": "command",
            "command": "$(pwd)/.claude/smart-commit-hook.sh",
            "description": "Smart commit after session completion (token optimized)"
          }
        ]
      }
    ]
  },
  "workflowOptimization": {
    "autoCommitOnStop": true,
    "tddModeAvailable": true,
    "tokenOptimized": true,
    "uvIntegrated": $USE_UV,
    "preCommitEnabled": $USE_PRECOMMIT
  }
}
EOF

    log_success "Claude settings配置完成"
}

# 创建CLAUDE.md
create_claude_md() {
    log_step "创建CLAUDE.md..."
    
    # 复制基础模板
    if [ -f "claude-base-template.md" ]; then
        cp claude-base-template.md CLAUDE.md
    else
        # 从当前目录复制模板（如果存在）
        TEMPLATE_PATH="/home/pharmacy/PharmacyRAG/claude-base-template.md"
        if [ -f "$TEMPLATE_PATH" ]; then
            cp "$TEMPLATE_PATH" CLAUDE.md
        else
            log_error "找不到CLAUDE.md模板文件"
            exit 1
        fi
    fi
    
    log_success "CLAUDE.md创建完成"
}

# 显示安装结果
show_installation_summary() {
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 安装完成！                                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BLUE}📋 已安装功能:${NC}"
    echo "  ✅ 智能自动提交 (对话结束后触发)"
    echo "  ✅ Git安全检查和冲突防护"  
    echo "  ✅ MCP服务配置 (context7, grep, spec-workflow)"
    echo "  ✅ TDD输出样式 (使用 /output-style tdd)"
    echo "  ✅ Linus风格代码规范"
    
    if [ "$USE_UV" = true ]; then
        echo "  ✅ uv Python项目管理"
        echo "  ✅ 开发依赖 (pytest, black, isort, mypy)"
    fi
    
    if [ "$USE_PRECOMMIT" = true ]; then
        echo "  ✅ pre-commit代码质量检查"
    fi
    
    echo -e "\n${YELLOW}💡 使用方式:${NC}"
    echo "  • 正常开发，Claude会在对话结束后自动提交"
    echo "  • 切换到TDD模式: /output-style tdd"
    echo "  • 查看可用样式: /output-style"
    echo "  • 手动提交: ./.claude/smart-commit-hook.sh"
    
    if [ "$USE_UV" = true ]; then
        echo -e "\n${PURPLE}🐍 uv命令:${NC}"
        echo "  • 运行脚本: uv run python main.py"
        echo "  • 运行测试: uv run pytest"
        echo "  • 添加依赖: uv add package-name"
    fi
    
    if [ "$USE_PRECOMMIT" = true ]; then
        echo -e "\n${GREEN}✨ pre-commit:${NC}"
        echo "  • 手动运行: uv run pre-commit run --all-files"
        echo "  • 代码会在git commit时自动检查"
    fi
    
    echo -e "\n${BLUE}🔧 后台任务管理:${NC}"
    echo "  • 查看后台任务: jobs"
    echo "  • 停止推送: kill <PID>"
    
    echo -e "\n${GREEN}📖 详细说明请查看 CLAUDE.md${NC}"
}

# 主函数
main() {
    # 参数处理
    if [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    collect_configuration
    check_dependencies
    initialize_project
    setup_claude_dirs
    create_smart_commit_hook
    create_tdd_output_style
    
    if [ "$USE_UV" = true ]; then
        setup_precommit
    fi
    
    setup_mcp_services
    update_claude_settings
    create_claude_md
    
    show_installation_summary
}

# 执行主函数
main "$@"
EOF

    chmod +x setup-claude-workflow-enhanced.sh
    log_success "增强版安装脚本创建完成"
}

<function_calls>
<invoke name="TodoWrite">
<parameter name="todos">[{"content": "\u67e5\u770b\u5f53\u524d\u5df2\u914d\u7f6e\u7684MCP\u670d\u52a1", "status": "completed"}, {"content": "\u67e5\u770buv\u548cpre-commit\u6587\u6863", "status": "completed"}, {"content": "\u4fdd\u7559CLAUDE.md\u4e2d\u7684\u539f\u59cb\u63d0\u793a\u8bcd", "status": "completed"}, {"content": "\u91cd\u6784\u4e00\u952e\u811a\u672c\u652f\u6301uv\u4ed3\u5e93\u521b\u5efa", "status": "completed"}, {"content": "\u6dfb\u52a0MCP\u81ea\u52a8\u914d\u7f6e\u529f\u80fd", "status": "completed"}, {"content": "\u79fb\u9664TDD\u8bf4\u660e\uff0c\u6539\u4e3a\u7b80\u5355\u63d0\u53caoutput-style\u53ef\u9009", "status": "in_progress"}, {"content": "\u6dfb\u52a0\u67e5\u770b\u6587\u6863\u7684\u63d0\u793a", "status": "pending"}]